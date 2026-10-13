"""Scraper listing 99.co -> CSV skema union (dataset/raw_sources/99co_<kota>.csv)

Patuh robots.txt: cuman mengambil halaman listing SEO /id/jual/rumah/...
(tanpa /api, /ajax, /id/cari/, dan parameter filter yang dilarang).
Pagination SSR tidak tersedia (selalu page 1), jadi pendalaman dilakukan
lewat halaman kecamatan internal per kota.

Keputusan Rute C (disetujui tim+dosen, Okt 2026): volume kecil sebatas
gerbang n>=200 per kota, jeda antar request, field faktual saja.

Pemakaian:
  python dataset/raw_sources/scrape_99co.py surabaya [--target 250] [--max-districts 15]
"""
import argparse
import csv
import json
import os
import random
import re
import time
import urllib.request

BASE = "https://www.99.co"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/126"
HERE = os.path.dirname(os.path.abspath(__file__))
OUTCOLS = ["sumber", "lokasi", "luas_m2", "luas_bangunan", "jumlah_kamar",
           "jumlah_kamar_mandi", "usia_bangunan", "harga"]


def fetch(url, retries=2):
    req = urllib.request.Request(url, headers={
        "User-Agent": UA,
        "Accept": "text/html,application/xhtml+xml",
        "Accept-Language": "id,en;q=0.8",
    })
    for attempt in range(retries + 1):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                if resp.status == 200:
                    return resp.read().decode("utf-8", errors="replace")
        except Exception as e:
            print(f"  retry {attempt+1} {url} ({e})")
            time.sleep(10)
    return None


def next_data(html):
    m = re.search(
        r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>',
        html, re.S)
    if not m:
        return None
    try:
        return json.loads(m.group(1))["props"]["pageProps"]["data"]
    except Exception:
        return None


def kecamatan_links(data, city_slug):
    for grp in data.get("internalLinks", []):
        title = (grp.get("title") or "").lower()
        if title.startswith("kecamatan di"):
            out = []
            for it in grp.get("data", []):
                url = it.get("url") or ""
                if "/jual/rumah/" in url and "/sewa/" not in url:
                    out.append((url, int(it.get("count") or 0)))
            return sorted(out, key=lambda x: -x[1])
    return []


def _area(attr):
    if isinstance(attr, dict):
        try:
            v = float(str(attr.get("value", "")).strip())
            return v if v > 0 else None
        except ValueError:
            return None
    return None


def extract_listing(item, want_city):
    attrs = item.get("attributes") or {}
    if (attrs.get("property_type") or {}).get("value") != "rumah":
        return None
    if (attrs.get("market_type") or {}).get("value") != "secondary":
        return None
    if item.get("clusters"):
        return None
    city = ((item.get("location") or {}).get("city") or {}).get("name", "")
    if city.strip().lower() != want_city.strip().lower():
        return None
    price = ((item.get("price") or {}).get("price") or 0)
    lt = _area(attrs.get("land_area"))
    if not price or price <= 0 or not lt:
        return None
    usia = _area(attrs.get("building_age"))
    yb = attrs.get("year_built") or 0
    if not usia and isinstance(yb, (int, float)) and yb > 1900:
        usia = max(0, time.localtime().tm_year - int(yb))
    return {
        "luas_m2": lt,
        "luas_bangunan": _area(attrs.get("builtup_area")),
        "jumlah_kamar": attrs.get("bedrooms"),
        "jumlah_kamar_mandi": attrs.get("bathrooms"),
        "usia_bangunan": usia,
        "harga": price,
        "id": item.get("id"),
    }


def scrape_city(city_slug, display_name, target, max_districts, delay):
    src = f"99.co/{display_name}"
    seen, rows = set(), []

    def absorb(url):
        html = fetch(url)
        if not html:
            return 0
        data = next_data(html)
        if not data:
            return 0
        added = 0
        for grp in data.get("listings", []):
            for item in (grp.get("data") or []):
                r = extract_listing(item, display_name)
                if r and r["id"] not in seen:
                    seen.add(r["id"])
                    rows.append(r)
                    added += 1
        return added

    city_url = f"{BASE}/id/jual/rumah/{city_slug}"
    html = fetch(city_url)
    if not html:
        print("Gagal mengambil halaman kota")
        return rows
    data = next_data(html)
    if not data:
        print("NEXT_DATA tidak ditemukan")
        return rows
    for grp in data.get("listings", []):
        for item in (grp.get("data") or []):
            r = extract_listing(item, display_name)
            if r and r["id"] not in seen:
                seen.add(r["id"])
                rows.append(r)
    print(f"  halaman kota: {len(rows)} baris")

    dists = kecamatan_links(data, city_slug)[:max_districts]
    for url, count in dists:
        if len(rows) >= target:
            break
        time.sleep(delay + random.uniform(0, 1))
        added = absorb(BASE + url)
        print(f"  {url}  (+{added}, total {len(rows)})")
    return rows[:target]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("city", help="slug kota di 99.co, mis. surabaya")
    ap.add_argument("--name", help="nama kota tampil, default title-case slug")
    ap.add_argument("--target", type=int, default=250)
    ap.add_argument("--max-districts", type=int, default=15)
    ap.add_argument("--delay", type=float, default=2.5)
    a = ap.parse_args()
    display = a.name or a.city.replace("-", " ").title()

    rows = scrape_city(a.city, display, a.target, a.max_districts, a.delay)
    out = os.path.join(HERE, f"99co_{a.city}.csv")
    with open(out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=OUTCOLS)
        w.writeheader()
        for r in rows:
            w.writerow({
                "sumber": f"99.co/{display}",
                "lokasi": display,
                "luas_m2": r["luas_m2"],
                "luas_bangunan": r["luas_bangunan"] or "",
                "jumlah_kamar": r["jumlah_kamar"] if r["jumlah_kamar"] is not None else "",
                "jumlah_kamar_mandi": r["jumlah_kamar_mandi"] if r["jumlah_kamar_mandi"] is not None else "",
                "usia_bangunan": r["usia_bangunan"] if r["usia_bangunan"] is not None else "",
                "harga": r["harga"],
            })
    n = len(rows)
    miss = lambda k: sum(1 for r in rows if r[k] in (None, 0))
    print(f"Simpan {n} baris -> {out}")
    print(f"  kosong: luas_bangunan={miss('luas_bangunan')} kamar={miss('jumlah_kamar')} "
          f"km={miss('jumlah_kamar_mandi')} usia={miss('usia_bangunan')}")


if __name__ == "__main__":
    main()
