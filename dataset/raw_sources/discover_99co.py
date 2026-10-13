"""Discover: indeks kota se-Indonesia dari halaman provinsi 99.co.
Output: dataset/raw_sources/99co_city_index.json  [{slug,nama,provinsi,count}]
Halaman provinsi yang tidak ada -> dilewati diam-diam.
"""
import json
import os
import re
import time
import urllib.request

from scrape_99co import BASE, fetch, next_data

HERE = os.path.dirname(os.path.abspath(__file__))

PROVINSI = [
    "aceh", "sumatera-utara", "sumatera-barat", "riau", "jambi",
    "sumatera-selatan", "bengkulu", "lampung", "kepulauan-bangka-belitung",
    "kepulauan-riau", "jakarta", "jawa-barat", "jawa-tengah", "yogyakarta",
    "jawa-timur", "banten", "bali", "kalimantan-barat",
    "kalimantan-tengah", "kalimantan-selatan", "kalimantan-timur",
    "kalimantan-utara", "sulawesi-utara", "sulawesi-tengah",
    "sulawesi-selatan", "sulawesi-tenggara", "gorontalo", "sulawesi-barat",
    "maluku", "maluku-utara", "papua", "papua-barat",
    "nusa-tenggara-barat", "nusa-tenggara-timur",
]
PROVINSI = sorted(set(PROVINSI))

KOTA_RE = re.compile(r"^(\d+)\s", )


def city_display(nama_url):
    return nama_url.replace("-", " ").title()


def main():
    out = {}
    for prov in PROVINSI:
        url = f"{BASE}/id/jual/rumah/{prov}"
        html = fetch(url, retries=0)
        time.sleep(2.0)
        if not html:
            print(f"  [lewati] {prov}: tidak ada halaman")
            continue
        data = next_data(html)
        if not data:
            print(f"  [lewati] {prov}: tanpa NEXT_DATA")
            continue
        found = 0
        for grp in (data.get("internalLinks") or []):
            title = (grp.get("title") or "").lower()
            if not title.startswith("kota di") and not title.startswith("kabupaten di"):
                continue
            for it in grp.get("data", []):
                u = it.get("url") or ""
                m = re.match(r"^/jual/rumah/([a-z0-9-]+)$", u)
                if not m:
                    continue
                slug = m.group(1)
                if slug == prov or slug in out:
                    continue
                loc = (data.get("location_info") or [{}])[0]
                out[slug] = {
                    "slug": slug,
                    "nama": city_display(slug),
                    "provinsi": loc.get("name") or prov,
                    "count": int(it.get("count") or 0),
                }
                found += 1
        print(f"  {prov}: +{found} kota (total {len(out)})")
    with open(os.path.join(HERE, "99co_city_index.json"), "w", encoding="utf-8") as f:
        json.dump(sorted(out.values(), key=lambda x: -x["count"]), f,
                  ensure_ascii=False, indent=1)
    print("Indeks tersimpan:", len(out), "kota")


if __name__ == "__main__":
    main()
