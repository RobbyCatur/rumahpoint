import json
import os

import joblib
import numpy as np
import pandas as pd
from flask import Flask, jsonify, request
from flask_cors import CORS

MODEL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "model")
META = json.load(open(os.path.join(MODEL_DIR, "meta.json"), encoding="utf-8"))
NUM_FEATURES = META["num_features"]
CAT_FEATURES = META["cat_features"]
CITY_TIERS = META.get("city_tiers", {})
# Garis "cukup data" yang sama dengan ml/build_wilayah.py (bendera `didukung` di asset mobile).
AMAN_MIN = 100
PERINGATAN_KURANG_DATA = ("Model belum punya cukup data untuk wilayah ini "
                          "— estimasi bisa kurang akurat.")
# ml/build_wilayah.py menulis jumlah baris per nama entitas wilayah (nama yang dikirim mobile).
# Kalau file itu belum ada (belum pernah training ulang sejak perubahan ini), pakai nama mentah
# dari meta.json.
CAKUPAN_PATH = os.path.join(MODEL_DIR, "cakupan_wilayah.json")
if os.path.exists(CAKUPAN_PATH):
    with open(CAKUPAN_PATH, encoding="utf-8") as f:
        CAKUPAN = json.load(f)
else:
    CAKUPAN = {c: int(v["n"]) for c, v in CITY_TIERS.items()}

reg_model = joblib.load(os.path.join(MODEL_DIR, "price_regression.joblib"))
clf_model = joblib.load(os.path.join(MODEL_DIR, "kategori_classifier.joblib"))
try:
    _MEDIAN_BANGUNAN = float(META["median_luas_bangunan"])
except KeyError:
    _MEDIAN_BANGUNAN = float("nan")

app = Flask(__name__)
CORS(app)  # izinkan request lintas-origin (uji via Chrome/desktop)


def _to_frame(payload: dict) -> pd.DataFrame:
    lb = payload.get("luas_bangunan", None)
    lb = float(lb) if lb not in (None, "", 0) else _MEDIAN_BANGUNAN
    row = {
        "luas_m2": float(payload.get("luas_m2", 0) or 0),
        "jumlah_kamar": float(payload.get("jumlah_kamar", 0) or 0),
        "jumlah_kamar_mandi": float(payload.get("jumlah_kamar_mandi", 0) or 0),
        "usia_bangunan": float(payload.get("usia_bangunan", 0) or 0),
        "luas_bangunan": lb,
        "lokasi": str(payload.get("lokasi", "")).replace("Jak. Utara", "Jakarta Utara").strip(),
    }
    return pd.DataFrame([row])


@app.get("/health")
def health():
    return jsonify({"status": "ok", "model": "Rumah Point"})


@app.post("/predict")
def predict():
    payload = request.get_json(silent=True) or {}
    required = ["luas_m2", "jumlah_kamar", "jumlah_kamar_mandi", "usia_bangunan", "lokasi"]
    missing = [k for k in required if payload.get(k) in (None, "")]
    if missing:
        return jsonify({"error": "field hilang", "missing": missing}), 400

    df = _to_frame(payload)
    log_price = reg_model.predict(df)[0]
    harga = float(10 ** log_price)
    kategori = str(clf_model.predict(df)[0])
    proba = clf_model.predict_proba(df)[0]
    conf = float(np.max(proba))
    # Rentang sederhana: +/- 25% sebagai indikasi (bukan interval statistik ketat)
    cukup_data = CAKUPAN.get(df.iloc[0]["lokasi"], 0) >= AMAN_MIN
    return jsonify({
        "estimasi_harga_rupiah": int(round(harga, -5)),
        "estimasi_harga_string": _rupiah(harga),
        "kategori_harga": kategori,
        "confidence": round(conf, 3),
        "cukup_data": cukup_data,
        "peringatan": None if cukup_data else PERINGATAN_KURANG_DATA,
        "rentang_bawah": _rupiah(harga * 0.75),
        "rentang_atas": _rupiah(harga * 1.25),
        "input": df.iloc[0].to_dict(),
    })


def _rupiah(x: float) -> str:
    x = int(round(x))
    if x >= 1_000_000_000:
        return f"Rp {x / 1_000_000_000:.2f} Miliar"
    if x >= 1_000_000:
        return f"Rp {x / 1_000_000:.0f} Juta"
    return f"Rp {x:,}".replace(",", ".")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8081")), debug=False)
