"""Tahap 1 — Pemeriksaan cakupan 514 kabupaten/kota (daftar induk kabkotlist.json).

Sifat daftar induk: 515 baris nama TANPA tipe; nama yang muncul 2x berarti
punya dua entitas (kota & kabupaten) — ada 26 nama seperti ini. Tipe entitas
tunggal diambil dari inventaris FLUS (satu-satunya sumber bereksplisit
"KAB"/"KOTA"); jika tak dikenal -> "?".

Pohon keputusan pemetaan lokasi union -> entitas induk:
  1. lokasi berprefiks eksplisit (dari FLUS)            -> entitas tipe tsb
  2. nama polos "X", induk tunggal                      -> entitas X
  3. nama polos "X", induk kembar (kota+kab)            -> default KOTA, dicatat ambigu
  4. nama tidak ada di induk                            -> "di luar daftar induk" (dilaporkan)

Jalankan:  python dataset/audit_cakupan.py
Keluaran:  dataset/cakupan_514.csv (per entitas induk)
           dataset/peetaan_lokasi.csv (per lokasi union + aturan yang dipakai)
"""
import csv
import json
import os
import re
import sys
import collections

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "raw_sources")
UNION = os.path.join(HERE, "properti_multi_kota.csv")
KABKOT = os.path.join(RAW, "kabkotlist.json")
FLUS = os.path.join(RAW, "kaggle_flus_housing.csv")
OUT_CAKUP = os.path.join(HERE, "cakupan_514.csv")
OUT_PETA = os.path.join(HERE, "peetaan_lokasi.csv")

AMAN, RINGAN, LV2, LV3 = 150, 100, 50, 10


def tier(n):
    if n >= AMAN:
        return 1
    if n >= RINGAN:
        return 2
    if n >= LV2:
        return 3
    if n >= LV3:
        return 4
    return 5


def title(s):
    s = re.sub(r"\s+", " ", str(s)).strip()
    return " ".join(w.capitalize() for w in s.split())


EXPLICIT = re.compile(r"^(Kabupaten|Kota Administrasi|Kota)\s+")


def inti(s):
    """Buang prefiks tipe: 'Kabupaten Bogor'/'Kota Bogor'/'Bogor' -> 'Bogor'."""
    s = title(s)
    m = EXPLICIT.match(s)
    return s[m.end():].strip() if m else s


def kunci(s):
    """Kunci pencocokan longgar: 'Gunung Kidul' ~ 'Gunungkidul', 'Banjarbaru' ~ 'Banjar Baru'."""
    return re.sub(r"[^a-z0-9]", "", s.lower())


def main():
    master = json.load(open(KABKOT, encoding="utf-8"))
    kemunculan = collections.Counter()
    prov = {}
    for m in master:
        core = title(m["kabkot"].replace("-", " "))
        if core.lower().startswith("kota "):
            core = core[5:]
        kemunculan[core] += 1
        prov.setdefault(core, title(m["provinsi"]))
    longgar = {}
    for c in kemunculan:
        longgar.setdefault(kunci(c), c)

    tipe_flus = collections.defaultdict(set)
    if os.path.exists(FLUS):
        for r in csv.DictReader(open(FLUS, encoding="utf-8")):
            cr = re.sub(r"\s+", " ", (r.get("city_regency") or "").upper()).strip()
            for pref, t in (("KOTA ADM", "kota adm"), ("KAB", "kabupaten"), ("KOTA", "kota")):
                if cr.startswith(pref):
                    c = title(cr[len(pref):].strip(". "))
                    if c and c != "Jakarta":
                        tipe_flus[c].add(t)
                    break

    baris = collections.Counter()
    sumber = collections.defaultdict(set)
    with open(UNION, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            baris[r["lokasi"]] += 1
            sumber[r["lokasi"]].add((r.get("sumber") or "").split("/")[0])

    ent_n = collections.Counter()
    ent_src = collections.defaultdict(set)
    peta, luar = [], []
    for lokasi, n in sorted(baris.items(), key=lambda x: -x[1]):
        m = EXPLICIT.match(lokasi)
        core = inti(lokasi)
        if kemunculan.get(core, 0) == 0 and kunci(core) in longgar:
            core = longgar[kunci(core)]
        if m:
            tipe = ("kabupaten" if m.group(1) == "Kabupaten"
                    else "kota adm" if "Administrasi" in m.group(1) else "kota")
            aturan = "eksplisit"
        elif kemunculan.get(core, 0) >= 2:
            tipe, aturan = "kota", "kembar: default-kota"
        elif kemunculan.get(core, 0) == 1:
            ts = tipe_flus.get(core)
            tipe, aturan = (";".join(sorted(ts)) if ts else "?"), "tunggal"
        else:
            tipe, aturan = "luar", "di-luar-induk"
            luar.append((lokasi, n, sorted(sumber[lokasi])))
        ent_n[(core, tipe)] += n
        ent_src[(core, tipe)] |= sumber[lokasi]
        peta.append(dict(lokasi_union=lokasi, inti=core, tipe=tipe, aturan=aturan,
                         baris=n, sumber=";".join(sorted(sumber[lokasi]))))

    cakupan = []
    for core, kem in kemunculan.items():
        if kem >= 2:
            varian = ["kota", "kabupaten"]
        else:
            ts = tipe_flus.get(core)
            varian = [ ";".join(sorted(ts)) ] if ts else ["?"]
        for t in varian:
            n = ent_n.get((core, t), 0) + (ent_n.get((core, "?"), 0) if t == "?" else 0)
            srcs = ent_src.get((core, t), set())
            if t == "?":
                srcs |= ent_src.get((core, "?"), set())
            cakupan.append(dict(inti=core, tipe=t, provinsi=prov[core],
                                jumlah_baris=n, sumber=";".join(sorted(srcs)),
                                status="berdata" if n else "NOL",
                                tier=tier(n) if n else "-"))
    cakupan.sort(key=lambda r: (-r["jumlah_baris"], r["inti"]))
    with open(OUT_CAKUP, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(cakupan[0].keys()))
        w.writeheader()
        w.writerows(cakupan)
    with open(OUT_PETA, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(peta[0].keys()))
        w.writeheader()
        w.writerows(peta)

    berdata = [c for c in cakupan if c["jumlah_baris"] > 0]
    by_tier = collections.Counter(c["tier"] for c in berdata)
    print(f"Entitas induk: {len(cakupan)}  (nama unik {len(kemunculan)}, "
          f"kembar {sum(1 for k in kemunculan.values() if k >= 2)})")
    print(f"Berdata >0 baris: {len(berdata)}   |   NOL: {len(cakupan) - len(berdata)}")
    for t in (1, 2, 3, 4, 5):
        print(f"  Tier {t}: {by_tier.get(t, 0)}")
    petai = collections.Counter(p["aturan"] for p in peta)
    print("\nAturan pemetaan terpakai (per lokasi union):", dict(petai))
    print(f"\nDi luar daftar induk: {len(luar)} lokasi, {sum(n for _, n, _ in luar)} baris")
    for l, n, s in sorted(luar, key=lambda x: -x[1])[:20]:
        print(f"  {l:30s} {n:5d}  {','.join(s)}")
    kembar = [p for p in peta if p["aturan"] == "kembar: default-kota"]
    print(f"\nKasus ambigu kembar (default KOTA): {len(kembar)}")
    for p in sorted(kembar, key=lambda x: -x["baris"])[:30]:
        print(f"  {p['inti']:24s} <- '{p['lokasi_union']}' {p['baris']:5d}  {p['sumber']}")
    nol = [c for c in cakupan if c["jumlah_baris"] == 0]
    print(f"\nEntitas NOL (contoh 25): {[c['inti'] for c in nol[:25]]}")
    print(f"\nTertulis: {os.path.relpath(OUT_CAKUP, HERE)}, "
          f"{os.path.relpath(OUT_PETA, HERE)}")


if __name__ == "__main__":
    main()
