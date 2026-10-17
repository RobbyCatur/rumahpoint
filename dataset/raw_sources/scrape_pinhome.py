#!/usr/bin/env python3
"""Pengumpul listing rumah Pinhome: halaman daftar kota (SRP) + halaman rinci.

robots.txt Pinhome hanya melarang halaman akun/agregasi; listing publik boleh.
Sopan: jeda >=4 detik + hurap acak antar permintaan, tanpa endpoint api/ajax.
Keluaran: pinhome_<slug>.csv berformat kolom union (lihat build_union.py).
Catatan: luas tanah TIDAK ada di halaman daftar — dibaca dari deskripsi
halaman rinci ("luas tanah 160 m²"); kosong bila tak tertulis.
"""
import urllib.request
import urllib.error
import re
import json
import time
import random
import csv
import os
import sys

BASE = "https://www.pinhome.id"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36"}
DELAY = 4.0
HERE = os.path.dirname(os.path.abspath(__file__))
OUTCOLS = ["sumber", "lokasi", "luas_m2", "luas_bangunan", "jumlah_kamar",
           "jumlah_kamar_mandi", "usia_bangunan", "harga"]


def fetch(url, tries=3):
    for a in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=45) as r:
                return r.read().decode("utf-8", "ignore")
        except urllib.error.HTTPError:
            return None
        except Exception:
            time.sleep(6)
    return None


def sleep():
    time.sleep(DELAY + random.random() * 2)


def num(s):
    if s is None:
        return None
    s = str(s).strip()
    if re.fullmatch(r"\d{1,3}(\.\d{3})+", s):
        s = s.replace(".", "")
    s = s.replace(",", ".")
    m = re.search(r"\d+(?:\.\d+)?", s)
    return float(m.group()) if m else None


def srp_items(html):
    out = []
    for b in re.findall(r'<script type="application/ld\+json">(.*?)</script>',
                        html, re.S):
        try:
            j = json.loads(b)
        except Exception:
            continue
        if isinstance(j, dict) and j.get("@type") == "ItemList":
            for it in j.get("itemListElement", []):
                d = it.get("item") or {}
                if d.get("@type") == "SingleFamilyResidence":
                    out.append(d)
    return out


LT_RE = re.compile(r"luas tanah\s*:?\s*([0-9][0-9.,]*)", re.I)


def pdp_luas_tanah(url):
    html = fetch(url)
    if not html:
        return None
    m = LT_RE.search(html)
    return num(m.group(1)) if m else None


def clean_url(u):
    return u.replace("pinhome.id//", "pinhome.id/")


def scrape_city(prov, slug, display, max_items=25):
    url = f"{BASE}/jual/rumah/{prov}/{slug}"
    html = fetch(url)
    if not html:
        print(f"  SRP gagal: {url}")
        return []
    items, seen, rows = [], set(), []
    for d in srp_items(html):
        u = clean_url(d.get("url", ""))
        if u and u not in seen:
            seen.add(u)
            items.append((u, d))
    rows = []
    n_lt = 0
    for u, d in items[:max_items]:
        offers = d.get("offers") or {}
        price = num(offers.get("price"))
        if not price or price <= 0:
            continue
        lb = num((d.get("floorSize") or {}).get("value"))
        kt = num((d.get("numberOfBedrooms") or {}).get("value"))
        km = num(d.get("numberOfBathroomsTotal"))
        sleep()
        lt = pdp_luas_tanah(u)
        if lt:
            n_lt += 1
        rows.append({"sumber": f"Pinhome/{display}", "lokasi": display,
                     "luas_m2": lt or "", "luas_bangunan": lb or "",
                     "jumlah_kamar": kt or "", "jumlah_kamar_mandi": km or "",
                     "usia_bangunan": "", "harga": price})
        print(f"    {len(rows):3d} lt={lt or '-':>7} lb={lb or '-':>6} "
              f"km={kt or '-'}/{km or '-'} harga={int(price)}")
    print(f"  {display}: {len(rows)} listing, {n_lt} berluas-tanah")
    return rows


def save(rows, slug):
    out = os.path.join(HERE, f"pinhome_{slug}.csv")
    with open(out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=OUTCOLS)
        w.writeheader()
        w.writerows(rows)
    return out


# target = kabupaten/kota tanpa data pada 139 entitas nol-cakupan
TARGETS = [
    ("aceh", "kab-aceh-barat-daya", "Aceh Barat Daya"),
    ("aceh", "kab-aceh-selatan", "Aceh Selatan"),
    ("aceh", "kab-aceh-tengah", "Aceh Tengah"),
    ("aceh", "kab-aceh-timur", "Aceh Timur"),
    ("aceh", "kab-nagan-raya", "Nagan Raya"),
    ("sumatera-utara", "kab-mandailing-natal", "Mandailing Natal"),
    ("sumatera-utara", "kab-nias-selatan", "Nias Selatan"),
    ("riau", "kab-rokan-hilir", "Rokan Hilir"),
    ("riau", "kab-siak", "Siak"),
    ("riau", "kab-kepulauan-meranti", "Kepulauan Meranti"),
    ("bengkulu", "kab-kepahiang", "Kepahiang"),
    ("nusa-tenggara-timur", "kab-alor", "Alor"),
    ("kalimantan-selatan", "kab-balangan", "Balangan"),
    ("kalimantan-timur", "bontang", "Bontang"),
    ("kepulauan-bangka-belitung", "kab-bangka-barat", "Bangka Barat"),
    ("sulawesi-tenggara", "kab-buton-selatan", "Buton Selatan"),
    ("maluku-utara", "kab-halmahera-timur", "Halmahera Timur"),
    ("maluku", "kab-seram-bagian-timur", "Seram Bagian Timur"),
]


def main():
    a = sys.argv[1] if len(sys.argv) > 1 else "0-17"
    lo, hi = (a.split("-") + [a.split("-")[0]])[:2]
    lo, hi = int(lo), int(hi)
    done_p = os.path.join(HERE, "pinhome_batch_done.txt")
    done = set(open(done_p).read().split()) if os.path.exists(done_p) else set()
    for i in range(lo, min(hi + 1, len(TARGETS))):
        prov, slug, disp = TARGETS[i]
        if slug in done:
            print(f"[{i+1}] {disp}: sudah selesai, lewati")
            continue
        print(f"[{i+1}/{len(TARGETS)}] {disp} <- {BASE}/jual/rumah/{prov}/{slug}")
        rows = scrape_city(prov, slug, disp)
        if rows:
            out = save(rows, slug)
            print(f"  simpan: {out} ({len(rows)} baris)")
        with open(done_p, "a") as f:
            f.write(slug + "\n")
    print("selesai rentang", a)


if __name__ == "__main__":
    main()
