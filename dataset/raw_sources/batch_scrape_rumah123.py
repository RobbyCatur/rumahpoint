"""Batch scrape rumah123: seluruh 332 kab/kota dari sitemap resmi (Okt 2026).

Resumable: kota yang CSV-nya sudah ada (rumah123_<slug>.csv) dilewati.
Progres -> rumah123_batch.log
Jalankan: python batch_scrape_rumah123.py [--target 50] [--only-new]
"""
import argparse
import json
import os
import re
import time

from scrape_rumah123 import HERE, _kecamatan, save_csv, scrape_city


def _tier(n):
    if n >= 150: return "T1-aman"
    if n >= 100: return "T2-warning-ringan"
    if n >= 50: return "T3-warning-lvl2"
    if n >= 10: return "T4-warning-lvl3"
    return "T5-sangat-terbatas"


def already(slug):
    return os.path.exists(os.path.join(HERE, f"rumah123_{slug}.csv"))


def _core(s):
    s = re.sub(r"\s+", " ", str(s)).strip().lower()
    return re.sub(r"^(kota adm\.|kota|kab\.|kabupaten)\s+", "", s)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", type=int, default=50)
    ap.add_argument("--max-pages", type=int, default=5)
    ap.add_argument("--max-districts", type=int, default=5)
    ap.add_argument("--delay", type=float, default=4.0)
    ap.add_argument("--prefer-new", action="store_true",
                    help="kerjakan lebih dulu kota yang belum ada di CSV 99co_*")
    a = ap.parse_args()

    covered99 = set()
    if a.prefer_new:
        import glob
        for f in glob.glob(os.path.join(HERE, "99co_*.csv")):
            covered99.add(_core(os.path.basename(f)[5:-4]))

    idx = json.load(open(os.path.join(HERE, "rumah123_city_index.json"), encoding="utf-8"))
    queue = [c for c in idx if not already(c["slug"])]
    if a.prefer_new:
        # kota yang belum ada di 99.co didahulukan; sisanya tetap dikerjakan (menambah kedalaman)
        queue.sort(key=lambda c: (_core(c["nama"]) in covered99 or _core(c["slug"]) in covered99))
    logf = open(os.path.join(HERE, "rumah123_batch.log"), "a", encoding="utf-8")

    def log(msg):
        print(msg, flush=True)
        logf.write(msg + "\n")
        logf.flush()

    log(f"=== batch rumah123 start: {len(queue)} kota (target={a.target}, prefer-new={a.prefer_new}) ===")
    for i, c in enumerate(queue, 1):
        t0 = time.time()
        try:
            rows = scrape_city(c["slug"], c["nama"], a.target, a.max_pages, a.max_districts, a.delay)
            save_csv(rows, c["slug"], c["nama"])
            log(f"[{i}/{len(queue)}] {c['nama']:28s} -> {len(rows):4d} baris "
                f"({time.time()-t0:.0f}s) {_tier(len(rows))}")
        except Exception as e:
            log(f"[{i}/{len(queue)}] {c['nama']:28s} -> GAGAL: {e}")
        time.sleep(4)
    log("=== batch rumah123 selesai ===")
    logf.close()


if __name__ == "__main__":
    main()
