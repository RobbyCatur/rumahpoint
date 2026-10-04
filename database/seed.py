"""
Rumah Point - Seed Database (A4: Web/Backend)
Membaca dataset UNION multi-kota (dataset/properti_multi_kota.csv) -> SQLite (database/properti.db).
Tabel `properti` kini punya kolom `sumber` & `luas_bangunan`.
Kategori `kategori_harga` dihitung PER-SENTILE PER-KOTA: harga >= median kotanya -> 'Mahal'.
Setelah seed, migrasi skema (migrate.py) dijalankan: tabel `cities` + kolom `city_id`.
Jalankan:  python database/seed.py   (env RP_DB untuk target DB lain)
"""
import csv
import os
import re
import sqlite3
import statistics

from migrate import apply as apply_migrations

BASE = os.path.dirname(os.path.abspath(__file__))
CSV = os.path.join(BASE, "..", "dataset", "properti_multi_kota.csv")
DB = os.getenv("RP_DB", os.path.join(BASE, "properti.db"))

TABLE_SQL = """
CREATE TABLE IF NOT EXISTS properti (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sumber TEXT,
    lokasi TEXT NOT NULL,
    luas_m2 REAL NOT NULL,
    luas_bangunan REAL,
    jumlah_kamar INTEGER,
    jumlah_kamar_mandi INTEGER,
    usia_bangunan INTEGER,
    harga REAL NOT NULL,
    kategori_harga TEXT
);
"""


def first_number(s):
    if s in (None, ""):
        return None
    m = re.search(r"-?\d+(?:[.,]\d+)?", str(s))
    return float(m.group(0).replace(",", ".")) if m else None


def to_int(s):
    v = first_number(s)
    return int(v) if v is not None else None


def main():
    if os.path.exists(DB):
        os.remove(DB)
    con = sqlite3.connect(DB)
    con.executescript(TABLE_SQL)

    data = []
    with open(CSV, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            lokasi = (r.get("lokasi") or "").strip()
            luas = first_number(r.get("luas_m2"))
            harga = first_number(r.get("harga"))
            if not lokasi or luas is None or not harga or harga <= 0:
                continue
            data.append(dict(
                sumber=r.get("sumber"), lokasi=lokasi, luas_m2=luas,
                luas_bangunan=first_number(r.get("luas_bangunan")),
                jumlah_kamar=to_int(r.get("jumlah_kamar")),
                jumlah_kamar_mandi=to_int(r.get("jumlah_kamar_mandi")),
                usia_bangunan=to_int(r.get("usia_bangunan")),
                harga=harga,
            ))

    # median harga per kota -> kategori per-sentile
    by_city = {}
    for d in data:
        by_city.setdefault(d["lokasi"], []).append(d["harga"])
    median = {c: statistics.median(v) for c, v in by_city.items()}
    for d in data:
        d["kategori_harga"] = "Mahal" if d["harga"] >= median[d["lokasi"]] else "Murah"

    con.executemany(
        "INSERT INTO properti (sumber, lokasi, luas_m2, luas_bangunan, jumlah_kamar,"
        " jumlah_kamar_mandi, usia_bangunan, harga, kategori_harga)"
        " VALUES (?,?,?,?,?,?,?,?,?)",
        [(d["sumber"], d["lokasi"], d["luas_m2"], d["luas_bangunan"], d["jumlah_kamar"],
          d["jumlah_kamar_mandi"], d["usia_bangunan"], d["harga"], d["kategori_harga"]) for d in data])
    con.commit()
    n = con.execute("SELECT COUNT(*) FROM properti").fetchone()[0]
    cities = con.execute("SELECT lokasi, COUNT(*) c FROM properti GROUP BY lokasi ORDER BY c DESC").fetchall()
    con.close()
    apply_migrations(DB)
    print(f"Seeded {n} rows -> {DB}")
    for c, cnt in cities:
        print(f"  {c:18s} {cnt:4d}  (median Rp {median[c]:,.0f})")


if __name__ == "__main__":
    main()
