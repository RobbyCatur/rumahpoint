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
# Label peringatan sesuai keputusan tim (tier murni dari jumlah sampel kota):
TIER_LABEL = {1: "aman", 2: "warning ringan", 3: "warning level 2",
              4: "warning level 3", 5: "warning level 4 - data lokal sangat terbatas"}

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
    city_info = CITY_TIERS.get(df.iloc[0]["lokasi"])
    tier = 5 if city_info is None else int(city_info["tier"])
    return jsonify({
        "estimasi_harga_rupiah": int(round(harga, -5)),
        "estimasi_harga_string": _rupiah(harga),
        "kategori_harga": kategori,
        "confidence": round(conf, 3),
        "tier": tier,
        "peringatan": TIER_LABEL[tier],
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
