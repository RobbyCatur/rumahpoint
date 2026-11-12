"""
Rumah Point - Seed Database (A4: Web/Backend)
Membaca dataset UNION multi-kota (dataset/properti_multi_kota.csv) -> SQLite (database/properti.db).
Tabel `properti` punya kolom `sumber` & `luas_bangunan`; `lokasi` menyimpan ejaan mentah.

Tiga aturan data diterapkan di sini (keputusan tim 12 Nov 2026):
- Baris mustahil dibuang: luas tanah < 10 m2 atau harga > Rp 1e8 per m2.
- usia_bangunan bercampur satuan: tahun 1900..tahun berjalan dikonversi menjadi umur;
  nilai di luar 0..126 (mis. placeholder 1111) dikosongkan lalu diimputasi saat latih.
- Ejaan lokasi dipetakan ke nama kanonik aset wilayah: nama telanjang digabung ke
  "Kabupaten X" hanya bila aset tidak punya entitas telanjang terpisah. Kolom `lokasi`
  tetap mentah; `city_id` menunjuk kota kanonik, dan kategori dihitung terhadap median
  kota kanonik itu.

Kategori `kategori_harga`: harga >= median kota kanonik -> 'Mahal'.
Setelah seed, migrasi skema (migrate.py) dijalankan, lalu kota diselaraskan.
Jalankan:  python database/seed.py   (env RP_DB untuk target DB lain)
"""
import csv
import datetime
import json
import os
import re
import sqlite3
import statistics

from migrate import apply as apply_migrations

BASE = os.path.dirname(os.path.abspath(__file__))
CSV = os.path.join(BASE, "..", "dataset", "properti_multi_kota.csv")
ASSET = os.path.join(BASE, "..", "mobile", "assets", "data", "wilayah.json")
DB = os.getenv("RP_DB", os.path.join(BASE, "properti.db"))

# Batas sama dengan ml/train.py (MAKS_HARGA_PER_M2, MIN_LUAS_TANAH).
MAKS_HARGA_PER_M2 = 1e8
MIN_LUAS_TANAH = 10

TAHUN_ACUAN = datetime.date.today().year
MAKS_UMUR = TAHUN_ACUAN - 1900

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


def muat_aset():
    with open(ASSET, encoding="utf-8") as f:
        wilayah = json.load(f)
    nama, provinsi = set(), {}
    for p in wilayah:
        for ent in p["kabupatenKota"]:
            nama.add(ent["nama"])
            provinsi[ent["nama"]] = p["nama"]
    return nama, provinsi


def kanonik(nama, aset):
    if nama in aset:
        return nama
    kandidat = "Kabupaten " + nama
    if kandidat in aset:
        return kandidat
    return nama


def normalisasi_usia(v):
    if v is None:
        return None, False
    v = int(v)
    if 1900 <= v <= TAHUN_ACUAN:
        return TAHUN_ACUAN - v, True
    if 0 <= v <= MAKS_UMUR:
        return v, False
    return None, False


def slugify(nama):
    return re.sub(r"[^a-z0-9]+", "-", nama.lower()).strip("-")


def selaraskan_kota(con, data, provinsi_aset):
    """Aktifkan kota kanonik, nonaktifkan ejaan lain, lalu isi city_id."""
    peta = {d["lokasi"]: d["lokasi_kanonik"] for d in data}
    existing = {r["nama"]: r["id"] for r in con.execute("SELECT id, nama FROM cities")}
    slugs = {r["slug"] for r in con.execute("SELECT slug FROM cities")}

    def pastikan_kota(nama):
        if nama in existing:
            return
        slug = slugify(nama)
        dasar, i = slug, 2
        while slug in slugs:
            slug = f"{dasar}-{i}"
            i += 1
        con.execute(
            "INSERT INTO cities (nama, slug, provinsi, status) VALUES (?,?,?,'aktif')",
            (nama, slug, provinsi_aset.get(nama, "Tidak Diketahui")))
        existing[nama] = con.execute(
            "SELECT id FROM cities WHERE nama=?", (nama,)).fetchone()[0]
        slugs.add(slug)

    # Semua entitas di aset tetap bisa dipilih admin meski belum punya baris.
    for nama in sorted(provinsi_aset):
        pastikan_kota(nama)
    for nama in sorted(set(peta.values())):
        pastikan_kota(nama)
    aktif = set(peta.values()) | set(provinsi_aset)
    for nama in existing:
        status = "aktif" if nama in aktif else "alias"
        con.execute("UPDATE cities SET status=? WHERE nama=?", (status, nama))
    for mentah, kanonik_nama in peta.items():
        con.execute(
            "UPDATE properti SET city_id=(SELECT id FROM cities WHERE nama=?) WHERE lokasi=?",
            (kanonik_nama, mentah))
    con.commit()


def main():
    if os.path.exists(DB):
        os.remove(DB)
    con = sqlite3.connect(DB)
    con.executescript(TABLE_SQL)
    aset, provinsi_aset = muat_aset()

    data = []
    dibuang = 0
    usia_dikonversi = 0
    usia_dikosongkan = 0
    with open(CSV, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            lokasi = (r.get("lokasi") or "").strip().replace("Jak. Utara", "Jakarta Utara")
            luas = first_number(r.get("luas_m2"))
            harga = first_number(r.get("harga"))
            if not lokasi or luas is None or not harga or harga <= 0:
                continue
            if luas < MIN_LUAS_TANAH or harga / luas > MAKS_HARGA_PER_M2:
                dibuang += 1
                continue
            usia, dikonversi = normalisasi_usia(to_int(r.get("usia_bangunan")))
            mentah_usia = to_int(r.get("usia_bangunan"))
            if mentah_usia is not None and usia is None:
                usia_dikosongkan += 1
            elif dikonversi:
                usia_dikonversi += 1
            data.append(dict(
                sumber=r.get("sumber"), lokasi=lokasi, luas_m2=luas,
                luas_bangunan=first_number(r.get("luas_bangunan")),
                jumlah_kamar=to_int(r.get("jumlah_kamar")),
                jumlah_kamar_mandi=to_int(r.get("jumlah_kamar_mandi")),
                usia_bangunan=usia,
                harga=harga,
                lokasi_kanonik=kanonik(lokasi, aset),
            ))

    by_city = {}
    for d in data:
        by_city.setdefault(d["lokasi_kanonik"], []).append(d["harga"])
    median = {c: statistics.median(v) for c, v in by_city.items()}
    for d in data:
        d["kategori_harga"] = "Mahal" if d["harga"] >= median[d["lokasi_kanonik"]] else "Murah"

    con.executemany(
        "INSERT INTO properti (sumber, lokasi, luas_m2, luas_bangunan, jumlah_kamar,"
        " jumlah_kamar_mandi, usia_bangunan, harga, kategori_harga)"
        " VALUES (?,?,?,?,?,?,?,?,?)",
        [(d["sumber"], d["lokasi"], d["luas_m2"], d["luas_bangunan"], d["jumlah_kamar"],
          d["jumlah_kamar_mandi"], d["usia_bangunan"], d["harga"], d["kategori_harga"])
         for d in data])
    con.commit()
    n = con.execute("SELECT COUNT(*) FROM properti").fetchone()[0]
    con.close()
    apply_migrations(DB)

    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    selaraskan_kota(con, data, provinsi_aset)
    kota_kanonik = con.execute("SELECT COUNT(DISTINCT city_id) FROM properti").fetchone()[0]
    kota_alias = con.execute("SELECT COUNT(*) FROM cities WHERE status='alias'").fetchone()[0]
    kota_aktif = con.execute("SELECT COUNT(*) FROM cities WHERE status='aktif'").fetchone()[0]
    con.close()

    print(f"Seeded {n} rows -> {DB}")
    print(f"  dibuang (mustahil)        : {dibuang}")
    print(f"  usia tahun -> umur        : {usia_dikonversi}")
    print(f"  usia placeholder -> kosong: {usia_dikosongkan}")
    print(f"  lokasi mentah             : {len({d['lokasi'] for d in data})}")
    print(f"  kota kanonik berdata      : {kota_kanonik}")
    print(f"  cities aktif / alias      : {kota_aktif} / {kota_alias}")


if __name__ == "__main__":
    main()
