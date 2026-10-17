"""Bangun dataset union multi-kota -> dataset/properti_multi_kota.csv
Sumber (raw_sources + dataset_properti.csv). Menyeragamkan kolom:
  sumber, lokasi(kota), luas_m2, luas_bangunan, jumlah_kamar, jumlah_kamar_mandi, usia_bangunan, harga
"""
import os, re, csv, glob

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "raw_sources")
UAS = os.path.join(HERE, "dataset_properti.csv")
OUT = os.path.join(HERE, "properti_multi_kota.csv")

NUM = ["luas_m2", "luas_bangunan", "jumlah_kamar", "jumlah_kamar_mandi", "usia_bangunan"]
OUTCOLS = ["sumber","lokasi","luas_m2","luas_bangunan","jumlah_kamar",
           "jumlah_kamar_mandi","usia_bangunan","harga"]
CAP_PER_CITY = 2000


def num(s):
    if s is None:
        return None
    s = str(s).replace("²", "").replace("\u00b2", "")
    m = re.search(r"\d+(?:[.,]\d+)?", s)
    return float(m.group(0).replace(",", ".")) if m else None


def price(s):
    """Parse harga dgn unit: 'Rp 542 Juta' -> 542e6; '1,2 M'; angka mentah."""
    if s is None:
        return None
    txt = str(s)
    low = txt.lower()
    val = num(txt)
    if val is None:
        return None
    if "miliar" in low or re.search(r"\bm\b", low):
        return val * 1_000_000_000
    if "juta" in low:
        return val * 1_000_000
    if "ribu" in low:
        return val * 1_000
    return val


def city_after_comma(s):
    if not s:
        return None
    part = [p.strip() for p in str(s).split(",") if p.strip()]
    return part[-1] if part else None


CITY_FIX = {
    "jakarta utara": "Jakarta Utara", "jakarta selatan": "Jakarta Selatan",
    "bekasi": "Bekasi", "bogor": "Bogor", "depok": "Depok",
    "tangerang": "Tangerang", "surabaya": "Surabaya",
}

# Kebijakan Okt 2026 (dua lorong, keputusan tim):
# Lorong 1 — nama non-administratif setingkat kecamatan/desa dengan induk tunggal
#   yang TERVERIFIKASI MANUAL -> dipetakan ke kabupaten induk (format sama FLUS).
# Lorong 2 — nama setingkat provinsi (Bali, Lampung, Aceh, ...) TIDAK dipetakan:
#   tetap ikut latih sebagai kategori "area propinsi", tapi tidak masuk daftar
#   pilihan kota 514. Daftar luar-induk terbaru: lihat dataset/cakupan_514.csv.
REMAP = {
    "Purwokerto": "Kabupaten Banyumas",
    "Cikarang": "Kabupaten Bekasi",
    "Ambarawa": "Kabupaten Semarang",
    "Anyer": "Kabupaten Serang",
    "Purwodadi": "Kabupaten Grobogan",
    "Cikampek": "Kabupaten Karawang",
    "Nusa Lembongan": "Kabupaten Klungkung",
    "Semarapura": "Kabupaten Klungkung",
    "Anambas": "Kabupaten Kepulauan Anambas",
    "Others": None,  # label sisa-sisa pengumpul -> buang barisnya
}


def norm_city(s):
    if not s:
        return None
    s = re.sub(r"\s+", " ", str(s)).strip()
    s = s.replace("Jak. Utara", "Jakarta Utara").replace("Jak. Selatan", "Jakarta Selatan")
    key = s.lower()
    return CITY_FIX.get(key, " ".join(w.capitalize() for w in s.split()))


def flus_lokasi(s):
    """'KAB BREBES' -> 'Kabupaten Brebes'; 'KOTA ADM. JAKARTA BARAT'/'KOTA X' -> 'X'."""
    if not s:
        return None
    t = re.sub(r"\s+", " ", str(s)).strip()
    m = re.match(r"^KAB(?:\.|UPATEN)?\s+(.+)$", t, re.I)
    if m:
        return "Kabupaten " + " ".join(w.capitalize() for w in m.group(1).split())
    m = re.match(r"^KOTA\s+(ADM\.?\s*)?(.+)$", t, re.I)
    if m:
        return " ".join(w.capitalize() for w in m.group(2).split())
    return " ".join(w.capitalize() for w in t.split())


# sitemap rumah123 regional (PropertyGuru) — bukan Indonesia
NON_ID = {"Singapore", "Australia", "Malaysia", "United Arab Emirates",
          "Thailand", "India"}


def read(path):
    with open(path, newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


def build():
    rows = []
    # 1) uas-properti (Jabodetabek): lokasi sudah kota
    for r in read(UAS):
        rows.append(dict(sumber="uas-properti/Jabodetabek",
                         lokasi=(r.get("lokasi") or "").replace("Jak. Utara", "Jakarta Utara").strip(),
                         luas_m2=num(r.get("luas_m2")),
                         luas_bangunan=None,
                         jumlah_kamar=num(r.get("jumlah_kamar")),
                         jumlah_kamar_mandi=num(r.get("jumlah_kamar_mandi")),
                         usia_bangunan=num(r.get("usia_bangunan")),
                         harga=num(r.get("harga"))))
    # 2) east_surabaya (rumah123): kota dari Alamat; Tipe=Rumah
    p2 = os.path.join(RAW, "east_surabaya.csv")
    for r in read(p2):
        if (r.get("Tipe Properti") or "").strip().lower() not in ("rumah", ""):
            continue
        rows.append(dict(sumber="rumah123/Surabaya",
                         lokasi=city_after_comma(r.get("Alamat")) or "Surabaya",
                         luas_m2=num(r.get("Luas Tanah")),
                         luas_bangunan=num(r.get("Luas Bangunan")),
                         jumlah_kamar=num(r.get("Kamar")),
                         jumlah_kamar_mandi=num(r.get("Kamar Mandi")),
                         usia_bangunan=num(r.get("Umur Bangunan")),
                         harga=price(r.get("Harga"))))
    # 3) rumah_bekasi (ColectDataRumah)
    p3 = os.path.join(RAW, "rumah_bekasi.csv")
    for r in read(p3):
        rows.append(dict(sumber="ColectDataRumah/Bekasi",
                         lokasi=city_after_comma(r.get("Lokasi")) or "Bekasi",
                         luas_m2=num(r.get("LT")),
                         luas_bangunan=num(r.get("LB")),
                         jumlah_kamar=num(r.get("Kamar")),
                         jumlah_kamar_mandi=num(r.get("Kamar Mandi")),
                         usia_bangunan=None,
                         harga=price(r.get("Harga"))))
    # 4) 99.co (Rute C, scrape langsung): file 99co_*.csv sudah berformat union
    for p in sorted(glob.glob(os.path.join(RAW, "99co_*.csv"))):
        for r in read(p):
            rows.append(dict(sumber=r.get("sumber"),
                             lokasi=r.get("lokasi"),
                             luas_m2=num(r.get("luas_m2")),
                             luas_bangunan=num(r.get("luas_bangunan")),
                             jumlah_kamar=num(r.get("jumlah_kamar")),
                             jumlah_kamar_mandi=num(r.get("jumlah_kamar_mandi")),
                             usia_bangunan=num(r.get("usia_bangunan")),
                             harga=num(r.get("harga"))))
    # 5) rumah123.com (scrape langsung, Okt 2026): file rumah123_*.csv berformat union
    for p in sorted(glob.glob(os.path.join(RAW, "rumah123_*.csv"))):
        for r in read(p):
            rows.append(dict(sumber=r.get("sumber"),
                             lokasi=r.get("lokasi"),
                             luas_m2=num(r.get("luas_m2")),
                             luas_bangunan=num(r.get("luas_bangunan")),
                             jumlah_kamar=num(r.get("jumlah_kamar")),
                             jumlah_kamar_mandi=num(r.get("jumlah_kamar_mandi")),
                             usia_bangunan=num(r.get("usia_bangunan")),
                             harga=num(r.get("harga"))))
    # 6) FLUS komersil (Kaggle zororaka, CC0 — data proyek pemerintah; subsidi TIDAK masuk latih)
    flus_p = os.path.join(RAW, "kaggle_flus_housing.csv")
    if os.path.exists(flus_p):
        for r in csv.DictReader(open(flus_p, encoding="utf-8")):
            if "subsidi" in (r.get("subsidy_status") or "").lower():
                continue
            rows.append(dict(sumber="FLUS/komersil",
                             lokasi=flus_lokasi(r.get("city_regency")),
                             luas_m2=num(r.get("land_area_m2")),
                             luas_bangunan=num(r.get("building_area_m2")),
                             jumlah_kamar=num(r.get("bedrooms")),
                             jumlah_kamar_mandi=num(r.get("bathrooms")),
                             usia_bangunan=None,
                             harga=num(r.get("price_idr"))))
    # 7) Pinhome (scrape langsung, Okt 2026): file pinhome_*.csv berformat union
    for p in sorted(glob.glob(os.path.join(RAW, "pinhome_*.csv"))):
        for r in read(p):
            rows.append(dict(sumber=r.get("sumber"),
                             lokasi=r.get("lokasi"),
                             luas_m2=num(r.get("luas_m2")),
                             luas_bangunan=num(r.get("luas_bangunan")),
                             jumlah_kamar=num(r.get("jumlah_kamar")),
                             jumlah_kamar_mandi=num(r.get("jumlah_kamar_mandi")),
                             usia_bangunan=num(r.get("usia_bangunan")),
                             harga=num(r.get("harga"))))
    # normalisasi kota + peta-ulang non-administratif + filter valid
    for r in rows:
        r["lokasi"] = norm_city(r["lokasi"])
        if r["lokasi"] in REMAP:
            r["lokasi"] = REMAP[r["lokasi"]]
    clean = [r for r in rows
             if r["lokasi"] and r["harga"] and r["harga"] > 0 and r["luas_m2"]
             and r["lokasi"] not in NON_ID]
    # cap per kota (keseimbangan)
    per, capped = {}, []
    for r in clean:
        c = per.get(r["lokasi"], 0)
        if c < CAP_PER_CITY:
            capped.append(r); per[r["lokasi"]] = c + 1
    with open(OUT, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=OUTCOLS)
        w.writeheader()
        for r in capped:
            w.writerow({k: ("" if r.get(k) is None else r.get(k)) for k in OUTCOLS})
    print("Total mentah:", len(rows), "-> valid:", len(clean), "-> capped:", len(capped))
    print("Per kota:")
    for k in sorted(per):
        print(f"  {k:20s} {per[k]}")


if __name__ == "__main__":
    build()
