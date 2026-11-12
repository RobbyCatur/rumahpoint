"""Bangun artefak dokumentasi model untuk halaman web read-only.

Membaca DB, artefak model yang SUDAH ADA, ml/metrics.json, dan hasil perbandingan.
Tidak melatih ulang, tidak menulis ke cloud_ml/model/.

Keluaran:
  web/static/dokumentasi/dokumentasi.json
  web/static/dokumentasi/*.svg
"""
import hashlib
import json
import os
import sys
from datetime import datetime, timezone

import joblib
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import sklearn
from sklearn.model_selection import train_test_split

BASE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(BASE)
DB = os.path.join(ROOT, "database", "properti.db")
CSV = os.path.join(ROOT, "dataset", "properti_multi_kota.csv")
MODEL_DIR = os.path.join(ROOT, "cloud_ml", "model")
OUT = os.path.join(ROOT, "web", "static", "dokumentasi")
TMP = os.path.join(ROOT, "tmp", "dok_eval")
sys.path.insert(0, BASE)
from build_wilayah import cocokkan, indeks_asset, indeks_provinsi  # noqa: E402
from train import (CAT_FEATURES, NUM_FEATURES, _first_number,  # noqa: E402
                   MAKS_HARGA_PER_M2, MIN_LUAS_TANAH)

os.makedirs(OUT, exist_ok=True)
WARNA = "#F59E0B"
NETRAL = "#334155"
plt.rcParams.update({"font.size": 9, "axes.edgecolor": "#94a3b8",
                     "axes.labelcolor": NETRAL, "text.color": NETRAL,
                     "xtick.color": NETRAL, "ytick.color": NETRAL,
                     "axes.facecolor": "white", "figure.facecolor": "white"})


def rupiah(n):
    if n >= 1e12:
        return f"Rp {n/1e12:.2f} T"
    if n >= 1e9:
        return f"Rp {n/1e9:.2f} M"
    if n >= 1e6:
        return f"Rp {n/1e6:.1f} jt"
    return f"Rp {n:,.0f}"


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8 * 1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def md5_tabel():
    import sqlite3
    h = hashlib.md5()
    con = sqlite3.connect(DB)
    for row in con.execute("SELECT * FROM properti ORDER BY rowid"):
        h.update("\x1f".join("" if v is None else str(v) for v in row).encode("utf-8"))
    con.close()
    return h.hexdigest()


def load_db():
    import sqlite3
    con = sqlite3.connect(DB)
    try:
        df = pd.read_sql_query(
            "SELECT p.*, c.nama AS lokasi_kanonik FROM properti p "
            "LEFT JOIN cities c ON c.id = p.city_id", con)
    except sqlite3.OperationalError:
        df = pd.read_sql_query("SELECT * FROM properti", con)
    con.close()
    df["_luas_raw"] = df["luas_m2"]
    df["_lb_raw"] = df["luas_bangunan"]
    df["_usia_raw"] = df["usia_bangunan"]
    df["lokasi"] = df["lokasi"].replace({"Jak. Utara": "Jakarta Utara"}).str.strip()
    if "lokasi_kanonik" in df.columns:
        kanonik = df["lokasi_kanonik"].fillna("").str.strip()
        df["lokasi"] = kanonik.where(kanonik != "", df["lokasi"])
    for col in NUM_FEATURES + ["harga"]:
        df[col] = df[col].map(_first_number)
    return df


def prep_for_split(df):
    out = df.dropna(subset=["harga", "lokasi"]).copy()
    out = out[(out["harga"] > 0) & out["luas_m2"].notna()].copy()
    medians = {}
    for col in NUM_FEATURES:
        med = float(out[col].median()) if out[col].notna().any() else 0.0
        medians[col] = med
        out[col] = out[col].fillna(med)
    if "kategori_harga" not in out.columns or out["kategori_harga"].isna().any():
        city_med = out.groupby("lokasi")["harga"].transform("median")
        out["kategori_harga"] = np.where(out["harga"] >= city_med, "Mahal", "Murah")
    out["log_harga"] = np.log10(out["harga"])
    return out, medians


def bad_mask(frame):
    luas = frame["luas_m2"].where(frame["luas_m2"] > 0)
    return ~((frame["luas_m2"] >= MIN_LUAS_TANAH) &
             (frame["harga"] / luas <= MAKS_HARGA_PER_M2))


def simpan(fig, nama, judul, keterangan, grafik):
    path = os.path.join(OUT, nama)
    fig.tight_layout()
    fig.savefig(path, format="svg", bbox_inches="tight")
    plt.close(fig)
    grafik.append({"file": nama, "judul": judul, "keterangan": keterangan})


def grafik_harga(df, grafik):
    harga = df["harga"].dropna()
    harga = harga[harga > 0]
    fig, (a, b) = plt.subplots(1, 2, figsize=(10, 3.4))
    bins = np.logspace(np.log10(harga.min()), np.log10(harga.max()), 45)
    a.hist(harga, bins=bins, color=WARNA, edgecolor="white", linewidth=.4)
    a.set_xscale("log")
    a.set_title("Harga asli (sumbu log)")
    a.set_xlabel("harga (Rp)")
    a.set_ylabel("jumlah baris")
    b.hist(np.log10(harga), bins=45, color=NETRAL, edgecolor="white", linewidth=.4)
    b.set_title("log10(harga) — target regresi")
    b.set_xlabel("log10(harga)")
    simpan(fig, "01-harga.svg", "Sebab transformasi log10",
           "Harga asli menjulur ekstrem; log10 membuat sebaran simetris dan galat relatif "
           "lebih adil.", grafik)


def grafik_luas(df, medians, grafik):
    fig, (a, b) = plt.subplots(1, 2, figsize=(10, 3.4))
    for ax, col, judul in ((a, "luas_m2", "Luas tanah (m²)"),
                           (b, "luas_bangunan", "Luas bangunan (m²)")):
        v = df[col].dropna()
        v = v[(v > 0) & (v <= v.quantile(0.99))]
        ax.hist(v, bins=45, color=WARNA, edgecolor="white", linewidth=.4)
        ax.axvline(medians[col], color="#0f172a", linestyle="--", linewidth=1)
        ax.set_title(judul)
        ax.set_xlabel("m²")
        ax.text(medians[col], ax.get_ylim()[1] * .9, f" median {medians[col]:g}",
                fontsize=8)
    simpan(fig, "02-luas.svg", "Sebaran luas dan garis imputasi",
           "Nilai kosong diisi median; garis putus-putus adalah nilai pengisi. Sumbu "
           "dipotong di persentil 99 untuk keterbacaan.", grafik)


def grafik_cakupan(cakupan, asset_counts, grafik):
    n = np.array(sorted(asset_counts.values()), dtype=float)
    n = np.sort(n)[::-1]
    fig, ax = plt.subplots(figsize=(10, 3.6))
    ax.plot(np.arange(1, len(n) + 1), np.maximum(n, 0.8), color=NETRAL, linewidth=1)
    ax.set_yscale("log")
    ax.axhline(100, color=WARNA, linestyle="--", linewidth=1.2)
    ax.text(len(n) * .02, 115, "garis cukup data: 100 baris", color=WARNA, fontsize=8)
    aman = int((n >= 100).sum())
    kosong = int((n == 0).sum())
    ax.set_title(f"Jumlah baris per wilayah ({len(n)} entitas)")
    ax.set_xlabel("peringkat wilayah")
    ax.set_ylabel("baris (skala log)")
    ax.annotate(f"{aman} wilayah ≥100", xy=(aman, 100), xytext=(aman + 40, 400),
                arrowprops=dict(arrowstyle="->", color=NETRAL), fontsize=8)
    ax.annotate(f"{kosong} wilayah belum berdata", xy=(len(n) - kosong / 2, 0.8),
                xytext=(len(n) * .55, 0.06), fontsize=8,
                arrowprops=dict(arrowstyle="->", color=NETRAL))
    simpan(fig, "03-cakupan.svg", "Cakupan data per wilayah",
           "Satu titik per kabupaten/kota di asset mobile; garis 100 adalah ambang "
           "peringatan yang dipakai form dan API.", grafik)


def grafik_belajar(by_city, grafik):
    xs = np.array([v["n"] for v in by_city.values()], dtype=float)
    ys = np.array([v["mae_rupiah"] for v in by_city.values()], dtype=float)
    fig, ax = plt.subplots(figsize=(9, 3.6))
    ax.scatter(xs, ys, s=14, color=WARNA, alpha=.65, edgecolor="none")
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.axvline(100, color=NETRAL, linestyle="--", linewidth=1)
    ax.set_xlabel("jumlah baris uji wilayah (skala log)")
    ax.set_ylabel("MAE wilayah (Rp, skala log)")
    ax.set_title("Galat per wilayah vs jumlah data (dasar ambang 100)")
    simpan(fig, "04-kurva-belajar.svg", "Mengapa ambangnya 100 baris",
           "Wilayah dengan sedikit baris uji punya galat jauh lebih besar; setelah ±100 "
           "baris sebaran galat mendatar.", grafik)


def grafik_galat(actual, pred, galat, grafik):
    rng = np.random.default_rng(0)
    idx = rng.choice(len(actual), size=min(3000, len(actual)), replace=False)
    fig, (a, b) = plt.subplots(1, 2, figsize=(10, 3.6))
    a.scatter(actual[idx], pred[idx], s=6, alpha=.3, color=NETRAL, edgecolor="none")
    lo, hi = max(actual.min(), pred.min()), max(actual.max(), pred.max())
    a.plot([lo, hi], [lo, hi], color=WARNA, linewidth=1)
    a.set_xscale("log")
    a.set_yscale("log")
    a.set_xlabel("harga asli (Rp)")
    a.set_ylabel("prediksi (Rp)")
    a.set_title("Prediksi vs aktual (contoh 3.000 baris uji)")
    ratio = np.maximum(actual / pred, pred / actual)
    ratio = ratio[np.isfinite(ratio)]
    bins = np.logspace(0, np.log10(max(ratio.max(), 3)), 45)
    b.hist(ratio, bins=bins, color=WARNA, edgecolor="white", linewidth=.4)
    b.set_xscale("log")
    b.axvline(galat["p50"], color=NETRAL, linestyle="--", linewidth=1)
    b.axvline(galat["p90"], color="#b91c1c", linestyle="--", linewidth=1)
    b.text(galat["p50"], b.get_ylim()[1] * .92, f" p50 {galat['p50']}×", fontsize=8)
    b.text(galat["p90"], b.get_ylim()[1] * .78, f" p90 {galat['p90']}×", fontsize=8)
    b.set_xlabel("rasio galat (prediksi ÷ aktual, skala log)")
    b.set_title("Sebaran rasio galat")
    simpan(fig, "05-galat.svg", "Bentuk galat sebenarnya",
           f"Setengah prediksi meleset ≤{galat['p50']}×, 90% ≤{galat['p90']}×. "
           f"Pita ±25% hanya menutup {galat['pita_25_persen_tertutup']}% harga asli.", grafik)


def grafik_confusion(cm, labels, grafik):
    fig, ax = plt.subplots(figsize=(4.2, 3.4))
    arr = np.array(cm)
    ax.imshow(arr, cmap="YlOrBr")
    for i in range(arr.shape[0]):
        for j in range(arr.shape[1]):
            ax.text(j, i, f"{arr[i, j]:,}", ha="center", va="center",
                    color="#0f172a", fontsize=10)
    ax.set_xticks(range(len(labels)), labels)
    ax.set_yticks(range(len(labels)), labels)
    ax.set_xlabel("prediksi")
    ax.set_ylabel("aktual")
    ax.set_title("Matriks konfusi (uji bersih)")
    simpan(fig, "06-konfusi.svg", "Klasifikasi Murah/Mahal",
           "Label diturunkan dari median harga per kota kanonik; akurasi dihitung pada "
           "baris uji setelah baris mustahil dibuang.", grafik)


def grafik_importance(nama, nilai, grafik):
    idx = np.argsort(nilai)[-20:]
    fig, ax = plt.subplots(figsize=(8, 4.2))
    ax.barh(np.arange(len(idx)), nilai[idx], color=WARNA)
    ax.set_yticks(np.arange(len(idx)), [nama[i] for i in idx], fontsize=7)
    ax.set_xlabel("importance")
    ax.set_title("20 fitur paling berpengaruh (RF produksi)")
    simpan(fig, "07-importance.svg", "Fitur yang paling dipakai model",
           "OneHot lokasi dipecah per kategori; batang teratas menunjukkan wilayah yang "
           "paling sering memisahkan harga.", grafik)


def grafik_perbandingan(models, grafik):
    reg = [(k, v) for k, v in models.items() if v["tugas"] == "regresi"]
    clf = [(k, v) for k, v in models.items() if v["tugas"] == "klasifikasi"]
    fig, (a, b) = plt.subplots(1, 2, figsize=(10, 3.8))
    for ax, rows, metrik, judul in (
            (a, reg, "r2", "Regresi — R² (lebih tinggi lebih baik)"),
            (b, clf, "accuracy", "Klasifikasi — akurasi (lebih tinggi lebih baik)")):
        rows = sorted(rows, key=lambda kv: kv[1]["metrik"][metrik])
        labels = [v["label_tabel"] for _, v in rows]
        vals = [v["metrik"][metrik] for _, v in rows]
        bars = ax.barh(np.arange(len(vals)), vals, color=WARNA)
        ax.set_yticks(np.arange(len(vals)), labels, fontsize=8)
        for bar, val in zip(bars, vals):
            ax.text(val, bar.get_y() + bar.get_height() / 2, f" {val:.3f}",
                    va="center", fontsize=7)
        ax.set_xlim(0, max(vals) * 1.25 if vals else 1)
        ax.set_title(judul)
    simpan(fig, "08-perbandingan.svg", "Perbandingan model",
           "Split sama, praproses sama; model bertanda subsampel dijelaskan di tabel. "
           "RF produksi dilatih ulang dengan konfigurasi yang sama.", grafik)


def main():
    df = load_db()
    data, medians_used = prep_for_split(df)
    bad = bad_mask(data)
    print(f"[data] {len(df)} baris, {data['lokasi'].nunique()} lokasi, "
          f"{int(bad.sum())} mustahil", flush=True)

    with open(os.path.join(MODEL_DIR, "meta.json"), encoding="utf-8") as f:
        meta = json.load(f)
    with open(os.path.join(BASE, "metrics.json"), encoding="utf-8") as f:
        metrics = json.load(f)
    with open(os.path.join(MODEL_DIR, "cakupan_wilayah.json"), encoding="utf-8") as f:
        cakupan = json.load(f)
    with open(os.path.join(BASE, "perbandingan_model.json"), encoding="utf-8") as f:
        banding = json.load(f)
    with open(os.path.join(TMP, "hasil-eval.json"), encoding="utf-8") as f:
        hasil = json.load(f)
    with open(os.path.join(ROOT, "mobile", "assets", "data", "wilayah.json"),
              encoding="utf-8") as f:
        asset = json.load(f)

    # --- split & prediksi model produksi (untuk grafik + provenance) ---
    train, test = train_test_split(data, test_size=0.2, random_state=42)
    test_bad = bad_mask(test)
    reg = joblib.load(os.path.join(MODEL_DIR, "price_regression.joblib"))
    Xte = test[NUM_FEATURES + CAT_FEATURES]
    p_log = reg.predict(Xte)
    te = test.copy()
    te["_pred_log"] = p_log
    clean = te[~test_bad]
    actual = (10 ** clean["log_harga"]).to_numpy()
    pred = (10 ** clean["_pred_log"]).to_numpy()
    print("[prediksi] selesai", flush=True)

    grafik = []
    grafik_harga(df, grafik)
    grafik_luas(df, {k: meta["median_" + k] for k in ("luas_m2", "luas_bangunan")},
                grafik)
    nama_asset = [e["nama"] for p in asset for e in p["kabupatenKota"]]
    asset_counts = {n: int(cakupan.get(n, 0)) for n in nama_asset}
    grafik_cakupan(cakupan, asset_counts, grafik)
    grafik_belajar(hasil["regression_by_city_bersih"], grafik)
    grafik_galat(actual, pred, hasil["galat_bersih"], grafik)
    grafik_confusion(hasil["klasifikasi_bersih"]["confusion_matrix"],
                     hasil["klasifikasi_bersih"]["labels"], grafik)

    prep = reg.named_steps["prep"]
    fitur = [str(x) for x in prep.get_feature_names_out()]
    fitur = [x.replace("num__", "").replace("cat__lokasi_", "lokasi: ") for x in fitur]
    imp = reg.named_steps["model"].feature_importances_
    grafik_importance(fitur, imp, grafik)
    grafik_perbandingan(banding["models"], grafik)

    # --- fakta praproses ---
    with open(CSV, encoding="utf-8") as f:
        baris_csv = sum(1 for _ in f) - 1
    harga_valid = df[df["harga"].notna() & df["luas_m2"].notna() & df["lokasi"].notna()]
    contoh_parsing = int(((df["harga"].notna()) & (df["luas_m2"].isna()) &
                          (df["_luas_raw"].notna())).sum())
    p1 = int(((pd.to_numeric(df["_luas_raw"], errors="coerce") == 1.0) &
              (pd.to_numeric(df["_lb_raw"], errors="coerce").fillna(0) > 100)).sum())
    usia_mentah = pd.to_numeric(df["_usia_raw"], errors="coerce")
    usia_umur = int(((usia_mentah >= 0) & (usia_mentah <= 126)).sum())
    usia_kosong = int(usia_mentah.isna().sum())
    lb_kosong = int(df["luas_bangunan"].isna().sum())

    # `sumber` di DB menyimpan label per portal/kota (513 nilai); kelompokkan ke 6 sumber.
    label = df["sumber"].fillna("(tanpa sumber)").astype(str).str.split("/").str[0]
    peta_sumber = {
        "FLUS": "FLUS/komersil (Kaggle)",
        "99.co": "99.co",
        "rumah123": "rumah123",
        "uas-properti": "uas-properti (GitHub)",
        "Pinhome": "Pinhome",
        "ColectDataRumah": "ColectDataRumah (GitHub)",
        "manual-web": "manual-web",
    }
    sumber = (label.map(lambda x: peta_sumber.get(x, x)).value_counts()
              .rename_axis("sumber").reset_index(name="baris")
              .sort_values("baris", ascending=False).to_dict("records"))
    kab, kota = indeks_asset(asset)
    jumlah, asal, _ = cocokkan(meta["city_tiers"], kab, kota)
    prov_of = {}
    for p in asset:
        for e in p["kabupatenKota"]:
            prov_of[e["nama"]] = p["nama"]
    prov_baris = {}
    for ent, names in asal.items():
        prov_baris[prov_of.get(ent, "(tidak terpetakan)")] = (
            prov_baris.get(prov_of.get(ent, "(tidak terpetakan)"), 0) +
            sum(meta["city_tiers"][n]["n"] for n in names))
    gabung = {k: v for k, v in asal.items() if len(v) > 1}
    baris_gabung = sum(jumlah[k] for k in gabung)
    aman_gabung = [k for k in gabung if jumlah[k] >= 100 and
                   max(meta["city_tiers"][n]["n"] for n in gabung[k]) < 100]
    aman = sum(1 for p in asset for e in p["kabupatenKota"] if e["didukung"])
    total_asset = sum(len(p["kabupatenKota"]) for p in asset)

    sisa_uji = hasil["split"]["n_uji_mustahil"]
    catatan_evaluasi = (
        f"Angka 'penuh' ({hasil['regression_full']['n']:,} baris) adalah yang tercatat "
        "di metrics.json. " +
        ("Seed sudah membuang baris mustahil sebelum split, jadi angka bersih sama dengan "
         "angka penuh." if sisa_uji == 0 else
         f"{sisa_uji} baris uji mustahil dikeluarkan dari angka bersih."))
    if aman_gabung:
        rincian_aman = "; ".join(
            f"{e} ({jumlah[e]} gabungan, terbesar "
            f"{max(meta['city_tiers'][n]['n'] for n in gabung[e])})"
            for e in aman_gabung)
        catatan_ejaan = (f" {len(aman_gabung)} di antaranya lolos ambang 100 hanya karena "
                         f"dijumlahkan: {rincian_aman}.")
    else:
        catatan_ejaan = " Tidak ada yang lolos ambang semata karena penjumlahan."

    dok = {
        "dibuat_pada": datetime.now(timezone.utc).isoformat(),
        "provenance": {
            "mesin": "laptop pengembang",
            "python": sys.version.split()[0],
            "sklearn": sklearn.__version__,
            "numpy": np.__version__,
            "pandas": pd.__version__,
            "joblib": __import__("joblib").__version__,
            "sha256_price_regression": sha256(os.path.join(MODEL_DIR, "price_regression.joblib")),
            "sha256_kategori_classifier": sha256(os.path.join(MODEL_DIR, "kategori_classifier.joblib")),
            "sha256_meta": sha256(os.path.join(MODEL_DIR, "meta.json")),
            "md5_tabel_properti": md5_tabel(),
            "jumlah_baris": int(len(df)),
            "jumlah_lokasi": int(df["lokasi"].nunique()),
            "split": {"test_size": 0.2, "random_state": 42,
                      "n_latih": int(len(train)), "n_uji": int(len(test))},
            "catatan": "Dihitung di laptop pada artefak yang sama dengan VPS; "
                       "halaman web hanya membaca berkas statis ini.",
        },
        "ringkasan": {
            "baris_mentah": int(len(df)),
            "baris_dilatih": int(len(data) - bad.sum()),
            "baris_dibuang": int(bad.sum()),
            "nama_lokasi": int(df["lokasi"].nunique()),
            "metrik_produksi": metrics["regression_randomforest"],
            "metrik_produksi_bersih": hasil["regression_bersih"],
            "klasifikasi_bersih": {
                k: hasil["klasifikasi_bersih"][k]
                for k in ("n", "accuracy", "precision", "recall", "f1")},
            "split_uji": hasil["split"],
        },
        "mengapa_rf": {
            "alasan": [
                "Fitur campuran (numerik + kategori lokasi dengan ratusan tingkat) dan "
                "interaksi nonlinear; RF menangani keduanya tanpa rekayasa fitur tambahan.",
                "Tahan nilai ekstrem dan tidak menuntut penskalaan, cocok untuk kolom "
                "hasil scraping yang belum seragam.",
                "Latih puluhan ribu baris selesai dalam hitungan menit di CPU tanpa GPU.",
                "Importance per fitur memberi bahan penjelasan ke pengguna.",
                "Inferensi cukup satu pipeline joblib; server tidak perlu pustaka tambahan.",
            ],
            "tabel": [
                {"model": v["label_tabel"], "tugas": v["tugas"],
                 "n_latih": v["n_latih"], "metrik": v["metrik"],
                 "waktu_latih_detik": v["waktu_latih_detik"],
                 "catatan": v["catatan"]}
                for v in banding["models"].values()
            ],
            "catatan_keadilan": [
                "Semua model memakai split dan praproses yang sama.",
                "SVR, SVC, dan KNN memakai subsampel karena skala penuh tidak layak "
                "secara komputasi; jumlah baris tercantum di tabel.",
                "RF yang dibandingkan adalah konfigurasi produksi (300 pohon), bukan "
                "versi yang dinaikkan demi menang.",
                "Hasil perbandingan tidak mengganti model produksi.",
            ],
        },
        "data": {
            "sumber": sumber,
            "provinsi_teratas": sorted(
                [{"provinsi": k, "baris": int(v)} for k, v in prov_baris.items()],
                key=lambda x: -x["baris"])[:10],
            "cakupan": {
                "entitas_asset": total_asset,
                "aman_n_ge_100": aman,
                "belum_berdata": int(sum(1 for v in asset_counts.values() if v == 0)),
            },
            "lisensi": [
                {"sumber": "FLUS (Kaggle)", "status": "CC0 Public Domain"},
                {"sumber": "99.co, rumah123", "status": "listing publik hasil scraping; "
                 "kepatuhan ToS didiskusikan tim dan dosen (belum final)"},
                {"sumber": "GitHub uas-properti, ColectDataRumah", "status": "lisensi "
                 "belum tercatat"},
                {"sumber": "Pinhome", "status": "lisensi/ToS belum tercatat"},
            ],
        },
        "praproses": [
            {"langkah": "Sumber mentah (CSV union)", "sebelum": baris_csv,
             "sesudah": int(len(df)),
             "catatan": f"{baris_csv - len(df)} baris mustahil (luas < 10 m² atau harga "
                        f"> Rp 100 juta/m²) dibuang saat seed; {df['lokasi'].nunique()} "
                        f"kota kanonik."},
            {"langkah": "Parsing angka dari teks", "sebelum": int(len(df)),
             "sesudah": int(len(harga_valid)),
             "catatan": f"{contoh_parsing} baris luas gagal diurai; "
                        f"{p1} baris 'luas_m2=1.0' berdampingan dengan bangunan >100 m²."},
            {"langkah": "Filter ekor di latih", "sebelum": int(len(data)),
             "sesudah": int(len(data) - bad.sum()),
             "catatan": f"{int(bad.sum())} baris tersaring; filter yang sama menjaga entri "
                        f"baru dari panel admin."},
            {"langkah": "Imputasi median", "sebelum": int(len(data)),
             "sesudah": int(len(data)),
             "catatan": f"luas_bangunan kosong {lb_kosong} baris -> "
                        f"{meta['median_luas_bangunan']:g}; usia_bangunan kosong "
                        f"{usia_kosong} baris -> {meta['median_usia_bangunan']:g}."},
            {"langkah": "log10(harga) + OneHot lokasi", "sebelum": int(len(data)),
             "sesudah": int(len(data)),
             "catatan": f"Model mengenal {len(prep.named_transformers_['cat'].categories_[0])} "
                        f"kategori lokasi dari {df['lokasi'].nunique()} kota kanonik."},
            {"langkah": "Split 80/20", "sebelum": int(len(data)),
             "sesudah": int(len(test)),
             "catatan": f"{len(train)} latih / {len(test)} uji; {int(test_bad.sum())} baris "
                        f"uji mustahil dikeluarkan saat evaluasi bersih."},
        ],
        "evaluasi_jujur": {
            "galat": hasil["galat_bersih"],
            "kota": hasil["kota"],
            "uji_bersih": hasil["regression_bersih"]["n"],
            "catatan": catatan_evaluasi,
        },
        "keterbatasan": [
            {"judul": "Usia bangunan sudah satu satuan",
             "isi": f"Seed mengubah nilai bertahun menjadi umur dan mengosongkan nilai di luar "
                    f"rentang; kini {usia_umur} baris berisi umur 0 sampai 126 dan {usia_kosong} "
                    f"baris kosong diisi median {meta['median_usia_bangunan']:g}. Mobile hanya "
                    f"mengirim 0 (Baru) atau 10 (Bekas), sedangkan model mengenal rentang usia "
                    f"yang jauh lebih lebar."},
            {"judul": "Lokasi disimpan dalam dua lapis",
             "isi": f"Tabel properti menyimpan ejaan mentah di kolom lokasi, sedangkan pelatihan "
                    f"membaca nama kota kanonik lewat city_id; {df['lokasi'].nunique()} kota "
                    f"dipakai sebagai kategori. Ejaan seperti 'Sidoarjo' dan 'Kabupaten Sidoarjo' "
                    f"sudah menyatu, dan nama yang tidak ada di aset wilayah memakai ejaan "
                    f"mentah apa adanya."},
            {"judul": "Sisa ejaan ganda di aset",
             "isi": f"{len(gabung)} entitas aset menerima lebih dari satu nama model "
                    f"({baris_gabung} baris); model tetap melihat keduanya sebagai kategori "
                    f"terpisah." + catatan_ejaan},
            {"judul": "Wilayah tanpa data",
             "isi": f"{int(sum(1 for v in asset_counts.values() if v == 0))} dari "
                    f"{total_asset} entitas belum punya baris; {aman} entitas ≥100 baris."},
            {"judul": "Bentuk galat lebar",
             "isi": f"Setengah prediksi meleset ≤{hasil['galat_bersih']['p50']}×, 90% "
                    f"≤{hasil['galat_bersih']['p90']}×; pita ±25% hanya menutup "
                    f"{hasil['galat_bersih']['pita_25_persen_tertutup']}% harga asli."},
        ],
        "perbandingan": {
            "split": banding["split"],
            "dataset": banding["dataset"],
            "catatan": banding["split"]["catatan"],
        },
        "grafik": grafik,
    }

    with open(os.path.join(OUT, "dokumentasi.json"), "w", encoding="utf-8") as f:
        json.dump(dok, f, ensure_ascii=False, indent=2)
    print(f"selesai: {len(grafik)} SVG + dokumentasi.json di {OUT}", flush=True)


if __name__ == "__main__":
    main()
