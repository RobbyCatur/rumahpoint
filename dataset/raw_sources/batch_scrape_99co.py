"""Batch scrape gelombang-2 99.co: semua kota count>=300 (keputusan tim Okt 2026).

Resumable: kota yang CSV-nya sudah ada dilewati. Progres -> 99co_batch.log
Jalankan:  python batch_scrape_99co.py [--min-count 300] [--target 400]
"""
import argparse
import json
import os
import time

from scrape_99co import HERE, save_csv, scrape_city

HERE_ = HERE


def already(slug):
    return os.path.exists(os.path.join(HERE_, f"99co_{slug}.csv"))


def _tier(n):
    if n >= 150:
        return "T1-aman"
    if n >= 100:
        return "T2-warning-ringan"
    if n >= 50:
        return "T3-warning-lvl2"
    return "T4-warning-lvl3"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-count", type=int, default=300)
    ap.add_argument("--target", type=int, default=400)
    ap.add_argument("--max-districts", type=int, default=30)
    ap.add_argument("--delay", type=float, default=2.5)
    a = ap.parse_args()

    idx = json.load(open(os.path.join(HERE_, "99co_city_index.json"), encoding="utf-8"))
    queue = [c for c in idx if c["count"] >= a.min_count and not already(c["slug"])]
    logf = open(os.path.join(HERE_, "99co_batch.log"), "a", encoding="utf-8")

    def log(msg):
        print(msg, flush=True)
        logf.write(msg + "\n")
        logf.flush()

    log(f"=== batch start: {len(queue)} kota (min-count={a.min_count}, target={a.target}) ===")
    for i, c in enumerate(queue, 1):
        t0 = time.time()
        try:
            rows = scrape_city(c["slug"], c["nama"], a.target, a.max_districts, a.delay)
            out = save_csv(rows, c["slug"], c["nama"])
            log(f"[{i}/{len(queue)}] {c['nama']:24s} -> {len(rows):4d} baris "
                f"({time.time()-t0:.0f}s) {_tier(len(rows))}")
        except Exception as e:
            log(f"[{i}/{len(queue)}] {c['nama']:24s} -> GAGAL: {e}")
        time.sleep(4)
    log("=== batch selesai ===")
    logf.close()


if __name__ == "__main__":
    main()
