"""Scraper listing rumah123.com -> CSV skema union (dataset/raw_sources/rumah123_<kota>.csv)

Patuh robots.txt: hanya halaman SEO /jual/<kabkot>/rumah/ (+ ?page=) dan halaman
detail /properti/... — keduanya tidak dilarang robots dan tersedia di sitemap
resmi (sitemap-srp-jual-rumah.xml, 332 kab/kota). Tidak menyentuh /api, portal-api,
atau parameter filter yang dilarang.

Data: SRP memuat 10 listing/halaman (harga, KT, KM, LB, lokasi) via JSON
__srp_seo_rescue; LT (luas tanah) hanya ada di halaman detail (listingInfo.landSize),
jadi tiap kandidat di-fetch 1x ke PDP. Baris tanpa harga/LT dibuang (aturan sama
seperti scraper 99.co).

Keputusan tim Okt 2026 (eksplorasi sumber menuju 200 kota): volume target per kota,
jeda >=4 detik, field faktual saja.

Pemakaian:
  python dataset/raw_sources/scrape_rumah123.py salatiga [--target 60] [--max-pages 6]
"""
import argparse
import csv
import json
import os
import random
import re
import time
import urllib.request

BASE = "https://www.rumah123.com"
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


def rescue_json(html):
    m = re.search(
        r'<script id="__srp_seo_rescue" type="application/json">(.*?)</script>',
        html, re.S)
    if not m:
        return None
    try:
        d, _ = json.JSONDecoder().raw_decode(m.group(1))
        return d
    except Exception:
        return None


def parse_price(s):
    """'Rp 349 Juta' -> 349000000 ; 'Rp 1,3 Miliar'/'Rp 2 M' -> ... ; 'Rp 5.750.000.000' -> int."""
    if not s:
        return 0
    s = s.replace("\xa0", " ").strip()
    m = re.search(r"([\d.,]+)\s*(Miliar|Mly|M\B|Juta|Jt|rb|Ribu)?", s)
    if not m:
        return 0
    num_s, unit = m.group(1), (m.group(2) or "").lower()
    if re.fullmatch(r"\d{1,3}([.]\d{3})+", num_s):        # 5.750.000.000 (titik = ribuan)
        val = float(num_s.replace(".", ""))
    else:
        val = float(num_s.replace(",", ".").replace(".", "", num_s.count(".") - 1)
                    if num_s.count(".") > 1 else num_s.replace(",", "."))
    if unit.startswith(("miliar", "mly", "m")):
        return int(val * 1_000_000_000)
    if unit.startswith(("juta", "jt")):
        return int(val * 1_000_000)
    if unit in ("rb", "ribu"):
        return int(val * 1_000)
    if val >= 1_000_000:  # tanpa unit, sudah rupiah penuh
        return int(val)
    return 0


def parse_area(s):
    """'65 m' / '1.600 m' / '45m2' -> float meter."""
    if not s:
        return None
    m = re.search(r"([\d.,]+)", str(s))
    if not m:
        return None
    t = m.group(1)
    if re.fullmatch(r"\d{1,3}([.]\d{3})+", t):
        return float(t.replace(".", ""))
    return float(t.replace(",", "."))


def listing_info(html):
    m = re.search(r'"listingInfo":(\{.*?\})', html, re.S)
    if not m:
        return None
    try:
        return json.loads(m.group(1))
    except Exception:
        return None


def pdp_usia(html):
    """Tahun Dibangun / umur bangunan kalau tampil di tabel spesifikasi DOM."""
    m = re.search(r'Tahun\s*Dibangun[^0-9]{0,120}(\d{4})', html, re.S)
    if m:
        y = int(m.group(1))
        if 1900 < y <= time.localtime().tm_year:
            return time.localtime().tm_year - y
    m = re.search(r'(?:Bangunan\s*(?:usia|Umur)\D{0,10}|\bUsia\s+Bangunan\D{0,10})(\d{1,2})\s*(?:th|tahun)', html, re.I | re.S)
    if m:
        return int(m.group(1))
    return None


def code_of(url):
    m = re.search(r'-h(o?s[a-z]?)(\d+)/?$', url)
    return (m.group(1) + m.group(2)) if m else url


def scrape_city(city_slug, display_name, target, max_pages, max_districts, delay):
    seen, candidates = set(), []

    def absorb_page(url):
        html = fetch(url)
        if not html:
            return 0
        d = rescue_json(html)
        if not d:
            return 0
        items = (d.get("structuredData") or {}).get("itemList", {}).get("items", [])
        added = 0
        for L in d.get("listings", []):
            code = code_of(L.get("url", ""))
            if not code or code in seen:
                continue
            seen.add(code)
            i = next((it for it in items if it.get("url") == L.get("url")), {})
            candidates.append({
                "code": code,
                "url": BASE + L["url"],
                "price": parse_price(L.get("price", "")),
                "lb": float(i.get("floorSize") or 0) or None,
                "kt": i.get("numberOfBedrooms"),
                "km": i.get("numberOfBathroomsTotal"),
            })
            added += 1
        return added

    n = absorb_page(f"{BASE}/jual/{city_slug}/rumah/")
    print(f"  halaman kota: {n} kandidat")
    for p in range(2, max_pages + 1):
        if len(candidates) >= target:
            break
        before = len(candidates)
        if absorb_page(f"{BASE}/jual/{city_slug}/rumah/?page={p}") == 0:
            break
        if len(candidates) == before:
            break
        time.sleep(delay + random.uniform(0, 1))

    for kec in _kecamatan(city_slug)[:max_districts]:
        if len(candidates) >= target:
            break
        absorb_page(f"{BASE}/jual/{city_slug}/{kec}/rumah/")
        time.sleep(delay + random.uniform(0, 1))

    rows = []
    for c in candidates:
        if len(rows) >= target:
            break
        time.sleep(delay + random.uniform(0, 1))
        html = fetch(c["url"])
        if not html:
            continue
        info = listing_info(html) or {}
        lt = parse_area(info.get("landSize"))
        price = c["price"] or parse_price(info.get("price", ""))
        if not price or not lt or lt <= 0:
            continue
        lb = parse_area(info.get("buildingSize")) or c["lb"]
        kt = info.get("bedrooms") or c["kt"]
        km = info.get("bathrooms") or c["km"]
        rows.append({
            "luas_m2": lt,
            "luas_bangunan": lb,
            "jumlah_kamar": int(kt) if str(kt or "").isdigit() else None,
            "jumlah_kamar_mandi": int(km) if str(km or "").isdigit() else None,
            "usia_bangunan": pdp_usia(html),
            "harga": price,
        })
        if len(rows) % 10 == 0:
            print(f"    {len(rows)}/{len(candidates)} baris OK")
    return rows


IDX_CACHE = None

def _kecamatan(city_slug):
    global IDX_CACHE
    if IDX_CACHE is None:
        p = os.path.join(HERE, "rumah123_city_index.json")
        IDX_CACHE = {c["slug"]: c.get("kecamatan", []) for c in json.load(open(p, encoding="utf-8"))} if os.path.exists(p) else {}
    return IDX_CACHE.get(city_slug, [])


def save_csv(rows, city_slug, display_name):
    out = os.path.join(HERE, f"rumah123_{city_slug}.csv")
    with open(out, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(OUTCOLS)
        for r in rows:
            w.writerow(["rumah123/" + display_name, display_name,
                        r["luas_m2"], r["luas_bangunan"], r["jumlah_kamar"],
                        r["jumlah_kamar_mandi"], r["usia_bangunan"], r["harga"]])
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("city_slug")
    ap.add_argument("--display", default=None, help="nama kota (default: slug title-case)")
    ap.add_argument("--target", type=int, default=60)
    ap.add_argument("--max-pages", type=int, default=6)
    ap.add_argument("--max-districts", type=int, default=6)
    ap.add_argument("--delay", type=float, default=4.0)
    a = ap.parse_args()
    display = a.display or " ".join(p.capitalize() for p in a.city_slug.split("-"))
    t0 = time.time()
    rows = scrape_city(a.city_slug, display, a.target, a.max_pages, a.max_districts, a.delay)
    out = save_csv(rows, a.city_slug, display)
    print(f"[{display}] {len(rows)} baris -> {os.path.basename(out)} ({time.time()-t0:.0f}s)")


if __name__ == "__main__":
    main()
