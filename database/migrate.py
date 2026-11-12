"""
Rumah Point - Migrasi Skema Database (idempotent, berbasis versi).
Setiap file database/migrations/NNN_nama.sql diterapkan berurutan, dicatat di
tabel schema_version, dan tidak pernah diterapkan dua kali.

Jalankan:  python database/migrate.py [--db PATH] [--verify]
Env:       RP_DB untuk override path DB (dipakai seed.py & uji).
"""
import argparse
import glob
import os
import sqlite3
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
MIGRATIONS = os.path.join(BASE, "migrations")
DEFAULT_DB = os.path.join(BASE, "properti.db")

VERSION_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS schema_version (
    versi INTEGER PRIMARY KEY,
    nama TEXT NOT NULL,
    diterapkan_pada TEXT NOT NULL DEFAULT (datetime('now'))
);
"""


def connect(path):
    con = sqlite3.connect(path)
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys=ON")
    return con


def applied_versions(con):
    con.executescript(VERSION_TABLE_SQL)
    return {r["versi"] for r in con.execute("SELECT versi FROM schema_version")}


def split_statements(sql):
    out, buf = [], []
    for line in sql.splitlines():
        stripped = line.strip()
        if stripped.startswith("--") or not stripped:
            continue
        buf.append(line)
        if stripped.endswith(";"):
            out.append("\n".join(buf))
            buf = []
    if buf:
        out.append("\n".join(buf))
    return out


def apply(db_path, verbose=True):
    con = connect(db_path)
    done = applied_versions(con)
    changed = []
    for path in sorted(glob.glob(os.path.join(MIGRATIONS, "*.sql"))):
        fname = os.path.basename(path)
        versi = int(fname.split("_", 1)[0])
        if versi in done:
            continue
        sql = open(path, encoding="utf-8").read()
        for stmt in split_statements(sql):
            try:
                con.execute(stmt)
            except sqlite3.OperationalError as e:
                # resume aman: ALTER yang kolomnya sudah ada bukan kegagalan
                if "duplicate column name" not in str(e):
                    raise
        con.execute("INSERT OR IGNORE INTO schema_version (versi, nama) VALUES (?,?)",
                    (versi, fname))
        con.commit()
        changed.append(fname)
        if verbose:
            print(f"[migrate] diterapkan: {fname}")
    con.execute("PRAGMA journal_mode=WAL")
    con.commit()
    con.close()
    if verbose and not changed:
        print("[migrate] tidak ada migrasi baru; skema sudah terkini.")
    return changed


def verify(db_path):
    """Gerbang verifikasi 002: tidak ada city_id NULL, join konsisten, FK bersih."""
    con = connect(db_path)
    errors = []
    try:
        n_null = con.execute(
            "SELECT COUNT(*) c FROM properti WHERE city_id IS NULL").fetchone()["c"]
        if n_null:
            errors.append(f"{n_null} baris properti punya city_id NULL")
        bad = con.execute(
            "SELECT COUNT(*) c FROM properti p JOIN cities c ON c.id=p.city_id "
            "WHERE c.status <> 'aktif'").fetchone()["c"]
        if bad:
            errors.append(f"{bad} baris: city_id menunjuk kota berstatus alias/nonaktif")
        fk = con.execute("PRAGMA foreign_key_check").fetchall()
        if fk:
            errors.append(f"foreign_key_check: {len(fk)} pelanggaran")
        per_city = con.execute(
            "SELECT c.nama, COUNT(*) n FROM properti p JOIN cities c ON c.id=p.city_id "
            "GROUP BY c.nama ORDER BY n DESC LIMIT 15").fetchall()
        print("[verify] sebaran per kota:")
        for r in per_city:
            print(f"    {r['nama']:18s} {r['n']:4d}")
    except sqlite3.OperationalError as e:
        errors.append(f"skema belum lengkap: {e}")
    con.close()
    if errors:
        for e in errors:
            print(f"[verify] GAGAL: {e}")
        return False
    print("[verify] OK: semua gerbang lolos.")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=os.getenv("RP_DB", DEFAULT_DB))
    ap.add_argument("--verify", action="store_true",
                    help="jalankan gerbang verifikasi tanpa menerapkan migrasi")
    args = ap.parse_args()
    if args.verify:
        sys.exit(0 if verify(args.db) else 1)
    apply(args.db)
    if not verify(args.db):
        sys.exit(1)


if __name__ == "__main__":
    main()
