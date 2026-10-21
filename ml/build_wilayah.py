"""Bangun ulang bendera `didukung` di asset mobile dari model terkini.

Dijalankan sesudah `ml/train.py`. Angka jumlah data tiap wilayah sudah ada di
`cloud_ml/model/meta.json` (key `city_tiers`, dihasilkan training yang biasa kamu
jalankan), jadi skrip ini hanya membaca kamus itu lalu menulis satu boolean per
entitas — tidak ada pelatihan ulang, tidak ada penambahan data.

    python ml/build_wilayah.py          # tulis mobile/assets/data/wilayah.json
    python ml/build_wilayah.py --cek    # hitung dan laporkan saja, tidak menulis

Aturan dan alasannya dicatat di docs/DISKUSI-PERINGATAN-CAKUPAN-DATA.md (§3, §5).
"""

import argparse
import json
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
META_PATH = ROOT / "cloud_ml" / "model" / "meta.json"
ASSET_PATH = ROOT / "mobile" / "assets" / "data" / "wilayah.json"
CAKUPAN_PATH = ROOT / "cloud_ml" / "model" / "cakupan_wilayah.json"

# Keputusan tim 21 Okt 2026: wilayah dianggap cukup data bila punya minimal
# AMAN_MIN baris di dataset latih. Garis diambil dari kurva belajar (kenaikan
# besar terakhir terjadi pada 50 -> 100 baris; sesudah 100 kurvanya landai),
# bukan dari target pengumpulan data 150 yang lama.
AMAN_MIN = 100


def _norm(s):
    """Kecilkan, buang tanda baca/spasi — untuk pencocokan nama.

    Kata sambung "dan" ikut dibuang karena asset menulis "Pangkajene Dan
    Kepulauan" sementara data latih menulis "Pangkajene Kepulauan".
    """
    s = unicodedata.normalize("NFKC", str(s)).lower().replace("&", " ")
    s = re.sub(r"\bdan\b", " ", s)
    return re.sub(r"[^a-z0-9]+", "", s)


def _urai(nama):
    """'Kabupaten Bekasi' -> ('kab','bekasi'); 'Kota Bekasi' -> ('kota','bekasi').

    Nama tanpa awalan ('Bekasi', 'Badung') -> ('telanjang','bekasi').
    """
    s = re.sub(r"\s+", " ", str(nama).strip())
    m = re.match(r"^(?:kab\.?|kabupaten)\s+(.*)$", s, flags=re.IGNORECASE)
    if m:
        return "kab", _norm(m.group(1))
    m = re.match(r"^kota\s+(.*)$", s, flags=re.IGNORECASE)
    if m:
        return "kota", _norm(m.group(1))
    return "telanjang", _norm(s)


def indeks_asset(wilayah):
    """Peta nama -> (provinsi, entitas) dari daftar resmi 515 kab/kota.

    Di `wilayah.json` kabupaten ditulis berawalan "Kabupaten " dan kota ditulis
    telanjang ("Bandung", "Tangerang"), jadi awalan menentukan petanya.
    """
    kab, kota = {}, {}
    for prov in wilayah:
        for ent in prov["kabupatenKota"]:
            tipe, inti = _urai(ent["nama"])
            if tipe == "kab":
                kab.setdefault(inti, (prov["nama"], ent))
            else:
                kota.setdefault(inti, (prov["nama"], ent))
    return kab, kota


def cocokkan(city_tiers, kab, kota):
    """Sebar jumlah baris model ke entitas asset. Kembalikan hasil + masalahnya."""
    jumlah = {}
    asal = {}
    tak_tercakup = []
    for nama, info in city_tiers.items():
        tipe, inti = _urai(nama)
        if tipe == "kab":
            # Sebagian kabupaten ditulis telanjang di asset ("Batang Hari",
            # "Banyu Asin"), jadi bila awalan tidak ketemu, coba nama telanjang.
            target = kab.get(inti) or kota.get(inti)
        elif tipe == "kota":
            target = kota.get(inti) or kab.get(inti)
        else:
            # Nama telanjang di data mentah paling sering berarti kota
            # (sumber memakai "Bekasi" untuk Kota Bekasi), jadi kota dicoba dulu.
            # Kalau tidak ada kota dengan nama itu, baru dianggap kabupaten.
            target = kota.get(inti) or kab.get(inti)
        if target is None:
            # Ada nama yang kebetulan berawalan "Kota " padahal satu kata di
            # daftar resmi ("Kota Baru" = Kabupaten Kotabaru). Coba nama utuh.
            inti_utuh = _norm(nama)
            target = kota.get(inti_utuh) or kab.get(inti_utuh)
        if target is None:
            tak_tercakup.append((nama, info["n"]))
            continue
        kunci = target[1]["nama"]
        jumlah[kunci] = jumlah.get(kunci, 0) + info["n"]
        asal.setdefault(kunci, []).append(nama)
    return jumlah, asal, tak_tercakup


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cek", action="store_true", help="hitung saja, jangan tulis file")
    args = ap.parse_args()

    meta = json.loads(META_PATH.read_text(encoding="utf-8"))
    city_tiers = meta.get("city_tiers")
    if not city_tiers:
        raise SystemExit(f"{META_PATH} tidak punya key city_tiers — jalankan python ml/train.py dulu.")

    asset = json.loads(ASSET_PATH.read_text(encoding="utf-8"))
    kab, kota = indeks_asset(asset)
    jumlah, asal, tak_tercakup = cocokkan(city_tiers, kab, kota)

    berubah = 0
    for prov in asset:
        for ent in prov["kabupatenKota"]:
            baru = jumlah.get(ent["nama"], 0) >= AMAN_MIN
            if baru != ent["didukung"]:
                berubah += 1
            ent["didukung"] = baru

    aman = sum(1 for p in asset for e in p["kabupatenKota"] if e["didukung"])
    total = sum(len(p["kabupatenKota"]) for p in asset)
    dikenali = sum(1 for p in asset for e in p["kabupatenKota"] if e["nama"] in jumlah)
    tak_tercakup.sort(key=lambda t: -t[1])

    print(f"Model: {len(city_tiers)} lokasi, {sum(v['n'] for v in city_tiers.values())} baris.")
    print(f"Asset: {total} kab/kota, {dikenali} dikenali nama model, "
          f"{aman} jadi aman (n>={AMAN_MIN}); {berubah} benderanya berubah.")
    if tak_tercakup:
        sisa = sum(n for _, n in tak_tercakup)
        print(f"\n{len(tak_tercakup)} nama di data latih tidak ada di daftar 515 "
              f"({sisa} baris) — perlu dibersihkan di database/seed.py:")
        for nama, n in tak_tercakup[:15]:
            print(f"  {nama:<34} {n:>6} baris")
        if len(tak_tercakup) > 15:
            print(f"  ... {len(tak_tercakup) - 15} lainnya")

    gabung = {k: v for k, v in asal.items() if len(v) > 1}
    if gabung:
        print(f"\n{len(gabung)} entitas menampung lebih dari satu nama data latih "
              f"(ejaan ganda di DB):")
        for ent, nama in list(gabung.items())[:10]:
            print(f"  {ent:<28} <- {', '.join(nama)}")

    if args.cek:
        print("\n--cek: file tidak ditulis.")
        return

    ASSET_PATH.write_text(
        json.dumps(asset, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    # Peta jumlah baris per nama entitas asset. Dibaca cloud_ml/app.py supaya API dan
    # bendera di form memakai angka yang sama — nama yang dikirim mobile adalah nama
    # asset, sedangkan meta.json memakai nama mentah dari DB ("Banyu Asin" vs "Banyuasin").
    CAKUPAN_PATH.write_text(
        json.dumps(dict(sorted(jumlah.items(), key=lambda kv: -kv[1])), ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"\nTulis {ASSET_PATH.relative_to(ROOT)} dan {CAKUPAN_PATH.relative_to(ROOT)}.")


if __name__ == "__main__":
    main()
