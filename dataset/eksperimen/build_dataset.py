"""Dataset EKSPERIMEN clustering (di luar pipeline Rumah Point - jangan diimport kode proyek).
Gabungan: 99.co 84 kota (listing sekunder) + FLUS nasional (proyek developer: komersil & subsidi).
Output: dataset_eksperimen.csv  (kolom seragam + pengaya FLUS utk fitur clustering).
Jalankan:  python dataset/eksperimen/build_dataset.py
"""
import csv
import glob
import os

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "..", "raw_sources")
OUT = os.path.join(HERE, "dataset_eksperimen.csv")

COLS = ["sumber", "segmen", "provinsi", "lokasi",
        "luas_m2", "luas_bangunan", "jumlah_kamar", "jumlah_kamar_mandi",
        "usia_bangunan", "harga", "rasio_bangunan",
        "jumlah_lantai", "status_proyek", "total_unit"]


def fnum(s):
    try:
        return float(str(s).replace(",", "."))
    except (TypeError, ValueError):
        return None


def flus_lokasi(raw):
    k = raw.strip().upper()
    if k.startswith("KOTA ADM "):
        return k[9:].title(), "Kota"
    if k.startswith("KOTA "):
        return k[5:].title(), "Kota"
    if k.startswith("KAB "):
        return "Kabupaten " + k[4:].title(), "Kabupaten"
    return k.title(), "Kota"


def main():
    rows = []
    for p in sorted(glob.glob(os.path.join(RAW, "99co_*.csv"))):
        for r in csv.DictReader(open(p, encoding="utf-8-sig")):
            lt, lb = fnum(r["luas_m2"]), fnum(r["luas_bangunan"])
            rows.append({
                "sumber": r["sumber"], "segmen": "sekunder",
                "provinsi": "", "lokasi": r["lokasi"],
                "luas_m2": lt, "luas_bangunan": lb,
                "jumlah_kamar": fnum(r["jumlah_kamar"]),
                "jumlah_kamar_mandi": fnum(r["jumlah_kamar_mandi"]),
                "usia_bangunan": fnum(r["usia_bangunan"]),
                "harga": fnum(r["harga"]),
                "rasio_bangunan": round(lb / lt, 4) if lt and lb else None,
                "jumlah_lantai": None, "status_proyek": "", "total_unit": None,
            })
    n_sub = n_kom = 0
    for r in csv.DictReader(open(os.path.join(RAW, "kaggle_flus_housing.csv"),
                                 encoding="utf-8")):
        harga = fnum(r["price_idr"])
        lt, lb = fnum(r["land_area_m2"]), fnum(r["building_area_m2"])
        if not harga or harga <= 0 or not lt:
            continue
        segmen = "proyek-subsidi" if r["subsidy_status"] == "subsidi" else "proyek-komersil"
        n_sub += r["subsidy_status"] == "subsidi"
        n_kom += r["subsidy_status"] != "subsidi"
        lokasi, _ = flus_lokasi(r["city_regency"])
        rows.append({
            "sumber": "FLUS/" + r["province"].strip().title(),
            "segmen": segmen,
            "provinsi": r["province"].strip().title(), "lokasi": lokasi,
            "luas_m2": lt, "luas_bangunan": lb,
            "jumlah_kamar": fnum(r["bedrooms"]),
            "jumlah_kamar_mandi": fnum(r["bathrooms"]),
            "usia_bangunan": 0 if segmen != "sekunder" else None,
            "harga": harga,
            "rasio_bangunan": round(lb / lt, 4) if lb else None,
            "jumlah_lantai": fnum(r["floors"]),
            "status_proyek": r["subsidy_status"],
            "total_unit": fnum(r["total_units"]),
        })
    with open(OUT, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=COLS)
        w.writeheader()
        for r in rows:
            w.writerow({k: ("" if v is None else v) for k, v in r.items()})
    kota = len({r["lokasi"] for r in rows})
    print(f"baris={len(rows)} (99.co sekunder + FLUS komersil {n_kom} + subsidi {n_sub})")
    print(f"lokasi unik={kota} -> {OUT}")


if __name__ == "__main__":
    main()
