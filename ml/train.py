"""
Rumah Point - Pelatihan Model Machine Learning (A2: ML Engineer)
- Regresi: prediksi harga (log10) -> baseline LinearRegression vs RandomForest
- Klasifikasi: kategori_harga (Murah/Mahal) -> RandomForestClassifier
Menyimpan pipeline model ke cloud_ml/model/ untuk dipakai endpoint /predict.
"""
import json
import os

import joblib
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import (accuracy_score, confusion_matrix, f1_score,
                             mean_absolute_error, mean_squared_error,
                             precision_score, recall_score, r2_score)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder

BASE = os.path.dirname(os.path.abspath(__file__))
CSV = os.path.join(BASE, "..", "dataset", "properti_multi_kota.csv")
DB = os.path.join(BASE, "..", "database", "properti.db")
OUT_DIR = os.path.join(BASE, "..", "cloud_ml", "model")
os.makedirs(OUT_DIR, exist_ok=True)

NUM_FEATURES = ["luas_m2", "luas_bangunan", "jumlah_kamar", "jumlah_kamar_mandi", "usia_bangunan"]
CAT_FEATURES = ["lokasi"]
TARGET_REG = "log_harga"
TARGET_CLF = "kategori_harga"

# Tier kualitas wilayah berdasarkan jumlah sampel di data latih (keputusan tim 21 Okt 2026,
# dasar: eksperimen kurva belajar di docs/DISKUSI-PERINGATAN-CAKUPAN-DATA.md §3 — kenaikan
# galat terbesar terjadi di bawah 25 baris dan kurva sudah landai setelah 100):
# 1 cukup data (n>=100) | 2 data terbatas (25<=n<100) | 3 sangat sedikit (n<25)
# Angka 150 yang lama dipakai sebagai target pengumpulan data, bukan penanda akurasi.
def city_tier(n):
    if n >= 100:
        return 1
    if n >= 25:
        return 2
    return 3


# Batas kewarasan baris data latih. Ada dua kelas baris yang merusak metrik dan keduanya
# sisa scraping, bukan properti nyata: harga per m2 yang tidak mungkin (placeholder digit
# berulang 111111111111111, dan iklan tanah 1 m2 seharga miliaran) serta luas tanah di
# bawah ukuran petak rumah mana pun. Diukur 22 Okt dari DB 64.650 baris: aturan ini memotong
# 167 baris (0,26 %) tanpa menjatuhkan satu wilayah pun dari garis 100.
# Ditaruh di sini (bukan di seed.py) supaya SEMUA sumber baris tercakup — CSV union, DB,
# maupun entri yang ditambahkan lewat panel admin — dan berlaku tanpa reseed.
MAKS_HARGA_PER_M2 = 1e8
MIN_LUAS_TANAH = 10


def _first_number(s):
    """Ambil angka pertama dari string, mis. '68.0 m2' -> 68.0 ; sudah numerik -> apa adanya."""
    if pd.isna(s):
        return np.nan
    if isinstance(s, (int, float)):
        return float(s)
    import re
    m = re.search(r"-?\d+(?:[.,]\d+)?", str(s))
    return float(m.group(0).replace(",", ".")) if m else np.nan


def load_and_clean():
    """Kembalikan (df, medians). Sumber utama: DB; fallback: CSV union."""
    if os.path.exists(DB):
        import sqlite3
        con = sqlite3.connect(DB)
        df = pd.read_sql_query("SELECT * FROM properti", con)
        con.close()
        src = "database"
    else:
        df = pd.read_csv(CSV)
        src = "csv"
    df["lokasi"] = df["lokasi"].replace({"Jak. Utara": "Jakarta Utara"}).str.strip()
    for col in NUM_FEATURES + ["harga"]:
        if col in df.columns:
            df[col] = df[col].map(_first_number)
    # kolom wajib: lokasi, luas_m2, harga
    df = df.dropna(subset=["harga", "lokasi"]).copy()
    df = df[(df["harga"] > 0) & df["luas_m2"].notna()]
    # potong ekor: tanah tak masuk akal / harga per m2 di luar dunia nyata
    luas = df["luas_m2"].where(df["luas_m2"] > 0)
    akal = (df["luas_m2"] >= MIN_LUAS_TANAH) & (df["harga"] / luas <= MAKS_HARGA_PER_M2)
    buang = int((~akal).sum())
    if buang:
        print(f"[ekor] buang {buang} baris tidak masuk akal "
              f"(luas tanah < {MIN_LUAS_TANAH} m2 atau harga > Rp {MAKS_HARGA_PER_M2:,.0f}/m2)")
    df = df[akal].copy()
    # imputasi median untuk numerik yang boleh kosong (mis. luas_bangunan/usia)
    medians = {}
    for col in NUM_FEATURES:
        if col not in df.columns:
            df[col] = np.nan
        med = float(df[col].median()) if df[col].notna().any() else 0.0
        medians["median_" + col] = med
        df[col] = df[col].fillna(med)
    # kategori (per-sentile per kota) bila belum ada (fallback CSV)
    if "kategori_harga" not in df.columns or df["kategori_harga"].isna().any():
        city_med = df.groupby("lokasi")["harga"].transform("median")
        df["kategori_harga"] = np.where(df["harga"] >= city_med, "Mahal", "Murah")
    df[TARGET_REG] = np.log10(df["harga"])
    print(f"[data] sumber={src}, baris={len(df)}, kota={df['lokasi'].nunique()}")
    return df.reset_index(drop=True), medians


def make_preprocessor() -> ColumnTransformer:
    return ColumnTransformer(
        transformers=[
            ("num", "passthrough", NUM_FEATURES),
            ("cat", OneHotEncoder(handle_unknown="ignore"), CAT_FEATURES),
        ]
    )


def evaluate_regression(model, X_test, y_test) -> dict:
    pred = model.predict(X_test)
    y_rupiah = 10 ** np.asarray(y_test)
    p_rupiah = 10 ** np.asarray(pred)
    return {
        "rmse_log10": round(float(np.sqrt(mean_squared_error(y_test, pred))), 4),
        "mae_log10": round(float(mean_absolute_error(y_test, pred)), 4),
        "r2": round(float(r2_score(y_test, pred)), 4),
        "mae_rupiah": int(mean_absolute_error(y_rupiah, p_rupiah)),
        "rmse_rupiah": int(np.sqrt(mean_squared_error(y_rupiah, p_rupiah))),
    }


def evaluate_classifier(model, X_test, y_test) -> dict:
    pred = model.predict(X_test)
    return {
        "accuracy": round(accuracy_score(y_test, pred), 4),
        "precision": round(precision_score(y_test, pred, average="weighted"), 4),
        "recall": round(recall_score(y_test, pred, average="weighted"), 4),
        "f1": round(f1_score(y_test, pred, average="weighted"), 4),
        "confusion_matrix": confusion_matrix(y_test, pred).tolist(),
        "labels": sorted(pd.unique(y_test).tolist()),
    }


def evaluate_regression_by_city(model, X_test, y_test):
    pred = model.predict(X_test)
    y_idr = 10 ** np.asarray(y_test)
    p_idr = 10 ** np.asarray(pred)
    out = {}
    tmp = X_test.copy()
    tmp["_y"], tmp["_p"] = y_idr, p_idr
    for city, g in tmp.groupby("lokasi"):
        if len(g) < 5:
            continue
        out[city] = {
            "n": int(len(g)),
            "mae_rupiah": int(mean_absolute_error(g["_y"], g["_p"])),
            "r2": round(float(r2_score(g["_y"], g["_p"])), 4) if len(g) > 1 else None,
        }
    return out


def main():
    df, medians = load_and_clean()
    X = df[NUM_FEATURES + CAT_FEATURES]
    y_reg = df[TARGET_REG]
    y_clf = df[TARGET_CLF]

    # Satu split yang sama dipakai untuk regresi & klasifikasi
    X_train, X_test, ytr_reg, yte_reg, ytr_clf, yte_clf = train_test_split(
        X, y_reg, y_clf, test_size=0.2, random_state=42
    )

    metrics = {}

    lin = Pipeline([("prep", make_preprocessor()), ("model", LinearRegression())])
    lin.fit(X_train, ytr_reg)
    metrics["regression_baseline_linreg"] = evaluate_regression(lin, X_test, yte_reg)

    rf = Pipeline([("prep", make_preprocessor()),
                   ("model", RandomForestRegressor(n_estimators=300, random_state=42, n_jobs=-1))])
    rf.fit(X_train, ytr_reg)
    metrics["regression_randomforest"] = evaluate_regression(rf, X_test, yte_reg)
    metrics["regression_by_city"] = evaluate_regression_by_city(rf, X_test, yte_reg)

    clf = Pipeline([("prep", make_preprocessor()),
                    ("model", RandomForestClassifier(n_estimators=300, random_state=42, n_jobs=-1))])
    clf.fit(X_train, ytr_clf)
    metrics["classification_kategori"] = evaluate_classifier(clf, X_test, yte_clf)

    joblib.dump(rf, os.path.join(OUT_DIR, "price_regression.joblib"))
    joblib.dump(clf, os.path.join(OUT_DIR, "kategori_classifier.joblib"))
    city_slugs = {}
    if os.path.exists(DB):
        import sqlite3
        con = sqlite3.connect(DB)
        try:
            city_slugs = {r[0]: r[1] for r in con.execute(
                "SELECT nama, slug FROM cities ORDER BY nama")}
        except sqlite3.OperationalError:
            pass
        con.close()
    counts = df["lokasi"].value_counts().to_dict()
    meta = {
        "num_features": NUM_FEATURES,
        "cat_features": CAT_FEATURES,
        "target_reg": "harga (log10)",
        "target_clf": TARGET_CLF,
        "cities": sorted(df["lokasi"].unique().tolist()),
        "city_tiers": {c: {"n": int(n), "tier": city_tier(int(n))}
                       for c, n in counts.items()},
        "city_slugs": city_slugs,  # nama -> slug; dipakai fase model per-kota (003)
        **medians,  # memuat median_luas_bangunan (dipakai cloud utk imputasi) dll.
    }
    with open(os.path.join(OUT_DIR, "meta.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
    with open(os.path.join(BASE, "metrics.json"), "w", encoding="utf-8") as f:
        json.dump(metrics, f, ensure_ascii=False, indent=2)

    print("=== METRIK ===")
    print(json.dumps(metrics, ensure_ascii=False, indent=2))
    print("\nModel tersimpan di", OUT_DIR)


if __name__ == "__main__":
    main()
