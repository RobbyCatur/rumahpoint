"""Perbandingan model untuk halaman /dokumentasi — offline, tidak menyentuh model produksi.

Split bersih (setelah filter ekor, 64.483 baris) dengan test_size=0.2, random_state=42.
Joblib produksi TIDAK dimuat dan TIDAK ditimpa; hanya JSON metrik yang ditulis.

Staging supaya bisa dijalankan bertahap (masing-masing < batas waktu shell):
  python ml/perbandingan.py --stage inti   # dummy, linreg, decision tree, gaussian nb, RF (reg+klf)
  python ml/perbandingan.py --stage svm    # SVR + SVC, subsampel 10.000 latih / 2.000 uji
  python ml/perbandingan.py --stage knn    # KNN, subsampel 5.000 latih / 2.000 uji
  python ml/perbandingan.py --gabung       # tulis ml/perbandingan_model.json
"""
import argparse
import json
import os
import platform
import sys
import time
from datetime import datetime, timezone

import numpy as np
import pandas as pd
import sklearn
from sklearn.compose import ColumnTransformer
from sklearn.dummy import DummyClassifier
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import (accuracy_score, confusion_matrix, f1_score,
                             mean_absolute_error, mean_squared_error,
                             precision_score, r2_score, recall_score)
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import GaussianNB
from sklearn.neighbors import KNeighborsClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.svm import SVC, SVR
from sklearn.tree import DecisionTreeClassifier

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)
from train import (CAT_FEATURES, NUM_FEATURES, TARGET_CLF, TARGET_REG,  # noqa: E402
                   load_and_clean)

ROOT = os.path.dirname(BASE)
PARTS = os.path.join(ROOT, "tmp", "dok_eval", "perbandingan_parts")
FINAL = os.path.join(BASE, "perbandingan_model.json")
SUBSAMPLE_SEED = 42
SUBSAMPLE_N = 10000
EVAL_N = 2000
KNN_TRAIN_N = 5000


def scaled_preprocessor():
    return ColumnTransformer([
        ("num", StandardScaler(), NUM_FEATURES),
        ("cat", OneHotEncoder(handle_unknown="ignore"), CAT_FEATURES),
    ])


def plain_preprocessor(sparse=True):
    return ColumnTransformer(
        [("num", "passthrough", NUM_FEATURES),
         ("cat", OneHotEncoder(handle_unknown="ignore"), CAT_FEATURES)],
        sparse_threshold=1.0 if sparse else 0.0,
    )


def reg_metrics(y_log, pred_log):
    y = 10 ** np.asarray(y_log)
    p = 10 ** np.asarray(pred_log)
    return {
        "r2": round(float(r2_score(y_log, pred_log)), 4),
        "mae_log10": round(float(mean_absolute_error(y_log, pred_log)), 4),
        "rmse_log10": round(float(np.sqrt(mean_squared_error(y_log, pred_log))), 4),
        "mae_rupiah": int(mean_absolute_error(y, p)),
        "rmse_rupiah": int(np.sqrt(mean_squared_error(y, p))),
    }


def clf_metrics(y, pred):
    return {
        "accuracy": round(float(accuracy_score(y, pred)), 4),
        "precision": round(float(precision_score(y, pred, average="weighted")), 4),
        "recall": round(float(recall_score(y, pred, average="weighted")), 4),
        "f1": round(float(f1_score(y, pred, average="weighted")), 4),
        "confusion_matrix": confusion_matrix(y, pred).tolist(),
        "labels": sorted(pd.unique(y).tolist()),
    }


def fit_eval(name, task, model, Xtr, ytr, Xte, yte, catatan):
    t0 = time.perf_counter()
    model.fit(Xtr, ytr)
    fit_s = time.perf_counter() - t0
    t1 = time.perf_counter()
    pred = model.predict(Xte)
    pred_s = time.perf_counter() - t1
    metrics = reg_metrics(yte, pred) if task == "regresi" else clf_metrics(yte, pred)
    row = {
        "tugas": task,
        "n_latih": int(len(Xtr)),
        "n_uji": int(len(Xte)),
        "waktu_latih_detik": round(fit_s, 2),
        "waktu_prediksi_detik": round(pred_s, 2),
        "metrik": metrics,
        "catatan": catatan,
    }
    print(f"[{name}] latih {fit_s:.1f}s prediksi {pred_s:.1f}s -> "
          f"{metrics.get('r2', metrics.get('accuracy'))}", flush=True)
    return row


def load_part(stage):
    path = os.path.join(PARTS, f"{stage}.json")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_part(stage, data):
    os.makedirs(PARTS, exist_ok=True)
    with open(os.path.join(PARTS, f"{stage}.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def split_data():
    df, medians = load_and_clean()
    X = df[NUM_FEATURES + CAT_FEATURES]
    y_reg = df[TARGET_REG]
    y_clf = df[TARGET_CLF]
    Xtr, Xte, ytr, yte, ctr, cte = train_test_split(
        X, y_reg, y_clf, test_size=0.2, random_state=42
    )
    print(f"[split] {len(Xtr)} latih / {len(Xte)} uji", flush=True)
    return Xtr, Xte, ytr, yte, ctr, cte, len(df), medians


def subsample(X, y, n, seed=SUBSAMPLE_SEED):
    if len(X) <= n:
        return X, y
    Xs, _, ys, _ = train_test_split(X, y, train_size=n, random_state=seed)
    return Xs, ys


def stage_inti():
    Xtr, Xte, ytr, yte, ctr, cte, n_rows, _ = split_data()
    part = load_part("inti")

    jobs = [
        ("dummy_most_frequent", "klasifikasi", "Dummy", "dummy",
         lambda: DummyClassifier(strategy="most_frequent"),
         "Garis bawah: selalu menebak kelas terbanyak.", False),
        ("linreg", "regresi", "LinearRegression", "plain",
         lambda: LinearRegression(),
         "Baseline linear; tanpa penskalaan (tidak dibutuhkan).", False),
        ("decision_tree", "klasifikasi", "DecisionTree", "plain",
         lambda: DecisionTreeClassifier(random_state=42),
         "Ablasi: satu pohon untuk menunjukkan peran ansambel.", False),
        ("gaussian_nb", "klasifikasi", "GaussianNB", "dense",
         lambda: GaussianNB(),
         "Asumsi normalitas; OneHot padat (sparse_threshold=0).", False),
        ("rf_regresi_produksi", "regresi", "RandomForest", "plain",
         lambda: RandomForestRegressor(n_estimators=300, random_state=42, n_jobs=-1),
         "Konfigurasi produksi dilatih ulang pada split bersih.", False),
        ("rf_klasifikasi_produksi", "klasifikasi", "RandomForest", "plain",
         lambda: RandomForestClassifier(n_estimators=300, random_state=42, n_jobs=-1),
         "Konfigurasi produksi dilatih ulang pada split bersih.", False),
    ]
    for name, task, label, prep, factory, note, _ in jobs:
        if name in part:
            print(f"[{name}] sudah ada, lewati", flush=True)
            continue
        if prep == "plain":
            model = Pipeline([("prep", plain_preprocessor()), ("model", factory())])
        elif prep == "dense":
            model = Pipeline([("prep", plain_preprocessor(sparse=False)), ("model", factory())])
        else:
            model = factory()
        row = fit_eval(name, task, model,
                       Xtr, ctr if task == "klasifikasi" else ytr,
                       Xte, cte if task == "klasifikasi" else yte,
                       note)
        row["label_tabel"] = label
        part[name] = row
        save_part("inti", part)


def stage_svm():
    Xtr, Xte, ytr, yte, ctr, cte, _, _ = split_data()
    part = load_part("svm")
    Xs, ysr = subsample(Xtr, ytr, SUBSAMPLE_N)
    _, ysc = subsample(Xtr, ctr, SUBSAMPLE_N)
    Xte_eval, yte_reg_eval = subsample(Xte, yte, EVAL_N, seed=7)
    _, yte_clf_eval = subsample(Xte, cte, EVAL_N, seed=7)

    jobs = [
        ("svr_rbf", "regresi", "SVR (RBF)", ysr, yte_reg_eval,
         lambda: Pipeline([("prep", scaled_preprocessor()), ("model", SVR(kernel="rbf"))]),
         f"Subsampel {SUBSAMPLE_N} latih / {EVAL_N} uji; StandardScaler di dalam pipeline "
         "(fitur numerik)."),
        ("svc_rbf", "klasifikasi", "SVC (RBF)", ysc, yte_clf_eval,
         lambda: Pipeline([("prep", scaled_preprocessor()),
                           ("model", SVC(kernel="rbf", cache_size=1000))]),
         f"Subsampel {SUBSAMPLE_N} latih / {EVAL_N} uji; StandardScaler di dalam pipeline."),
    ]
    for name, task, label, target, y_eval, factory, note in jobs:
        if name in part:
            print(f"[{name}] sudah ada, lewati", flush=True)
            continue
        row = fit_eval(name, task, factory(), Xs, target, Xte_eval, y_eval, note)
        row["label_tabel"] = label
        part[name] = row
        save_part("svm", part)


def stage_knn():
    Xtr, Xte, ytr, yte, ctr, cte, _, _ = split_data()
    part = load_part("knn")
    if "knn" in part:
        print("[knn] sudah ada, lewati", flush=True)
        return
    Xs, ysc = subsample(Xtr, ctr, KNN_TRAIN_N)
    Xte_eval, yte_eval = subsample(Xte, cte, EVAL_N, seed=7)
    model = Pipeline([("prep", scaled_preprocessor()),
                      ("model", KNeighborsClassifier(n_neighbors=5))])
    row = fit_eval(
        "knn", "klasifikasi", model, Xs, ysc, Xte_eval, yte_eval,
        f"Subsampel {KNN_TRAIN_N} latih / {EVAL_N} uji; ratusan kolom OneHot membuat jarak "
        "didominasi kota; skala penuh tidak layak secara komputasi.",
    )
    row["label_tabel"] = "KNeighborsClassifier"
    part["knn"] = row
    save_part("knn", part)


def gabung():
    models = {}
    for stage in ("inti", "svm", "knn"):
        models.update(load_part(stage))
    Xtr, Xte, ytr, yte, ctr, cte, n_rows, medians = split_data()
    out = {
        "dibuat_pada": datetime.now(timezone.utc).isoformat(),
        "provenance": {
            "mesin": platform.node(),
            "python": platform.python_version(),
            "sklearn": sklearn.__version__,
            "numpy": np.__version__,
            "pandas": pd.__version__,
        },
        "dataset": {
            "baris_setelah_filter": int(n_rows),
            "median_luas_bangunan": medians["median_luas_bangunan"],
            "median_usia_bangunan": medians["median_usia_bangunan"],
        },
        "split": {"test_size": 0.2, "random_state": 42,
                  "n_latih": int(len(Xtr)), "n_uji": int(len(Xte)),
                  "catatan": "Split yang sama dengan partisi model produksi pasca-reseed "
                             "12 Nov 2026; RF yang dibandingkan menghasilkan R² yang sama "
                             "dengan ml/metrics.json."},
        "models": models,
    }
    with open(FINAL, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print(f"ditulis {FINAL} ({len(models)} model)")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=["inti", "svm", "knn"])
    ap.add_argument("--gabung", action="store_true")
    args = ap.parse_args()
    if args.gabung:
        gabung()
    elif args.stage == "inti":
        stage_inti()
    elif args.stage == "svm":
        stage_svm()
    elif args.stage == "knn":
        stage_knn()
    else:
        ap.error("pilih --stage atau --gabung")
