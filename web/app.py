
import json
import os
import secrets
import sqlite3
import time
from functools import wraps

from flask import (Flask, jsonify, redirect, render_template_string, request,
                   session, url_for)

BASE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE, "..", "database", "properti.db")
DOK_JSON = os.path.join(BASE, "static", "dokumentasi", "dokumentasi.json")

# Daftar kota dibaca dari tabel `cities` (sumber kebenaran tunggal).
# Fallback ke DISTINCT lokasi bila DB belum dimigrasi (era string lama).
def city_options(con):
    try:
        rows = con.execute(
            "SELECT nama FROM cities WHERE status='aktif' ORDER BY nama").fetchall()
        return [r["nama"] for r in rows]
    except sqlite3.OperationalError:
        return [r["lokasi"] for r in con.execute(
            "SELECT DISTINCT lokasi FROM properti ORDER BY lokasi").fetchall()]


def city_id_for(con, nama):
    try:
        r = con.execute(
            "SELECT id FROM cities WHERE nama=? AND status='aktif'", (nama,)).fetchone()
    except sqlite3.OperationalError:
        return None
    return r["id"] if r else None

# Gerbang sementara sampai auth JWT penuh: satu password admin via env.
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "rumahpoint-admin")


def _secret_key():
    # Secret harus stabil antar-worker gunicorn: env dulu, lalu file persisten.
    key = os.getenv("SECRET_KEY")
    if key:
        return key
    path = os.path.join(BASE, ".secret_key")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return f.read().strip()
    key = secrets.token_hex(32)
    with open(path, "w", encoding="utf-8") as f:
        f.write(key)
    return key


app = Flask(__name__)
app.secret_key = _secret_key()


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get("admin"):
            if request.path.startswith("/api/"):
                return jsonify({"error": "unauthorized"}), 401
            return redirect(url_for("login"))
        return view(*args, **kwargs)
    return wrapped


def db():
    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    return con


def required_fields(payload):
    req = ["lokasi", "luas_m2", "jumlah_kamar", "jumlah_kamar_mandi",
           "usia_bangunan", "harga"]
    return [k for k in req if payload.get(k) in (None, "")]


STYLE = """
 body{font-family:system-ui,Arial;margin:0;color:#222;background:#fafafa}
 .wrap{max-width:960px;margin:0 auto;padding:0 20px}
 nav{background:#fff;border-bottom:1px solid #eee}
 nav .wrap{display:flex;align-items:center;justify-content:space-between;height:56px}
 .logo{font-weight:700;color:#00897b;text-decoration:none;font-size:18px}
 nav a.admin{font-size:13px;color:#666;text-decoration:none}
 .hero{text-align:center;padding:64px 20px 48px;background:linear-gradient(180deg,#e0f2f1,#fafafa)}
 .hero h1{font-size:34px;margin:0 0 12px}
 .hero p{color:#555;max-width:560px;margin:0 auto 24px;line-height:1.6}
 .btn{display:inline-block;background:#00897b;color:#fff;padding:12px 28px;border-radius:8px;
      text-decoration:none;font-weight:600}
 .stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:14px;
        max-width:760px;margin:-28px auto 0;padding:0 20px}
 .stat{background:#fff;border:1px solid #eee;border-radius:10px;padding:18px;text-align:center}
 .stat b{display:block;font-size:26px;color:#00897b}
 .stat span{font-size:13px;color:#666}
 section{padding:48px 0}
 h2{text-align:center;margin:0 0 28px}
 .cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px}
 .card{background:#fff;border:1px solid #eee;border-radius:10px;padding:20px}
 .card h3{margin:0 0 8px;font-size:16px;color:#00897b}
 .card p{margin:0;font-size:14px;color:#555;line-height:1.6}
 .num{display:inline-block;width:28px;height:28px;border-radius:50%;background:#00897b;
      color:#fff;text-align:center;line-height:28px;font-size:14px;font-weight:700;margin-bottom:10px}
 footer{border-top:1px solid #eee;background:#fff;padding:24px 0;text-align:center;
        color:#888;font-size:13px}
 .login-card{max-width:340px;margin:80px auto;background:#fff;border:1px solid #eee;
             border-radius:10px;padding:28px}
 .login-card h2{text-align:left;margin:0 0 16px}
 .login-card input{width:100%;box-sizing:border-box;padding:10px;margin-bottom:12px;
                   border:1px solid #ccc;border-radius:6px}
 .login-card button{width:100%;padding:10px;background:#00897b;color:#fff;border:0;
                    border-radius:6px;cursor:pointer;font-weight:600}
 .err{background:#ffebee;color:#c62828;padding:8px 10px;border-radius:6px;
      font-size:13px;margin-bottom:12px}
"""

LANDING = """<!doctype html>
<html lang="id"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Rumah Point: perkiraan harga rumah</title>
<meta name="description" content="Aplikasi Android yang memperkirakan harga rumah di Indonesia dari luas, kamar, usia bangunan, dan lokasi.">
<style>
.lp-page{margin:0;background:#FBFAF7;color:#0F172A;font-family:system-ui,-apple-system,"Segoe UI",Arial,sans-serif;-webkit-font-smoothing:antialiased}
.lp-wrap{max-width:1080px;margin:0 auto;padding:0 24px}
.lp-nav{border-bottom:1px solid #E7E5E0}
.lp-nav .lp-wrap{display:flex;align-items:center;justify-content:space-between;min-height:64px;gap:16px;flex-wrap:wrap}
.lp-logo{font-weight:700;font-size:18px;color:#0F172A;text-decoration:none;letter-spacing:-.01em}
.lp-navlinks{display:flex;gap:24px;flex-wrap:wrap}
.lp-navlinks a{font-size:14px;color:#475569;text-decoration:none}
.lp-navlinks a:hover{color:#0F172A}
.lp-hero{padding:84px 0 68px}
.lp-hero-grid{display:grid;grid-template-columns:minmax(0,1.35fr) minmax(0,1fr);gap:56px;align-items:start}
.lp-kicker{font-size:13px;font-weight:600;color:#B45309;margin:0 0 18px}
.lp-page h1{font-family:Georgia,"Times New Roman",serif;font-weight:700;font-size:clamp(36px,5vw,56px);line-height:1.06;letter-spacing:-.02em;margin:0 0 22px;max-width:15ch}
.lp-lead{font-size:18px;line-height:1.65;color:#334155;margin:0 0 30px;max-width:54ch}
.lp-actions{display:flex;align-items:center;gap:24px;flex-wrap:wrap}
.lp-btn{display:inline-block;background:#B45309;color:#fff;text-decoration:none;font-weight:600;font-size:15px;padding:13px 22px;border-radius:8px}
.lp-btn:hover{background:#92400E}
.lp-link{color:#0F172A;font-size:15px;text-decoration:none;border-bottom:1px solid #B45309;padding-bottom:2px}
.lp-page a:focus-visible{outline:2px solid #B45309;outline-offset:3px;border-radius:2px}
.lp-panel{background:#fff;border:1px solid #E7E5E0;border-radius:12px;padding:26px}
.lp-panel h2{font-size:15px;margin:0 0 14px;text-align:left}
.lp-panel ol{list-style:none;margin:0;padding:0}
.lp-panel li{padding:11px 0;border-top:1px solid #F1EFEA;font-size:14px;color:#334155}
.lp-panel li:first-child{border-top:0;padding-top:0}
.lp-note{font-size:12px;color:#64748B;line-height:1.55;margin:18px 0 0;padding-top:16px;border-top:1px solid #F1EFEA}
.lp-section{padding:72px 0;border-top:1px solid #E7E5E0}
.lp-section-alt{background:#F5F3EE}
.lp-page h2{font-family:Georgia,"Times New Roman",serif;font-size:clamp(26px,3vw,34px);line-height:1.15;letter-spacing:-.01em;margin:0 0 18px}
.lp-page .lp-panel h2{font-family:system-ui,-apple-system,"Segoe UI",Arial,sans-serif;font-size:15px;font-weight:700;letter-spacing:0;line-height:1.3;margin:0 0 12px}
.lp-page code{font-family:ui-monospace,Consolas,monospace;font-size:.92em;background:#F1EFEA;padding:2px 5px;border-radius:4px;color:#0F172A}
.lp-two{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1.2fr);gap:64px;align-items:start}
.lp-two > div > p,.lp-section > .lp-wrap > p{font-size:16px;line-height:1.7;color:#334155;margin:0}
.lp-steps{list-style:none;margin:0;padding:0}
.lp-steps li{display:grid;grid-template-columns:34px 1fr;gap:16px;padding:22px 0;border-top:1px solid #E7E5E0}
.lp-steps li:first-child{border-top:0;padding-top:0}
.lp-steps .n{font-family:Georgia,"Times New Roman",serif;font-size:18px;color:#B45309;line-height:1.2}
.lp-steps h3{font-size:16px;margin:0 0 6px}
.lp-steps p{font-size:15px;line-height:1.6;color:#475569;margin:0}
.lp-facts{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:1px;background:#E7E5E0;border:1px solid #E7E5E0;border-radius:12px;overflow:hidden;margin:26px 0 18px}
.lp-fact{background:#FBFAF7;padding:20px}
.lp-fact dt{font-size:12px;color:#64748B;margin:0 0 6px}
.lp-fact dd{margin:0;font-size:22px;font-family:Georgia,"Times New Roman",serif}
.lp-sources{list-style:none;margin:22px 0 0;padding:0}
.lp-sources li{display:flex;justify-content:space-between;gap:16px;padding:11px 0;border-top:1px solid #E7E5E0;font-size:14px;color:#334155}
.lp-sources li:first-child{border-top:0}
.lp-sources b{font-weight:600;font-variant-numeric:tabular-nums}
.lp-download .lp-wrap{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:32px;align-items:center}
.lp-status{display:inline-block;font-size:12px;border:1px solid #E7E5E0;border-radius:999px;padding:5px 10px;color:#64748B;background:#fff}
.lp-footer{border-top:1px solid #E7E5E0;padding:28px 0;font-size:13px;color:#64748B}
.lp-footer .lp-wrap{display:flex;justify-content:space-between;gap:16px;flex-wrap:wrap}
.lp-footer a{color:#0F172A;text-decoration:none}
.lp-footer a:hover{text-decoration:underline}
@media(max-width:860px){
 .lp-hero{padding:56px 0 48px}
 .lp-hero-grid,.lp-two,.lp-download .lp-wrap{grid-template-columns:1fr;gap:36px}
 .lp-facts{grid-template-columns:1fr}
 .lp-section{padding:56px 0}
}
</style></head><body class="lp-page">
<nav class="lp-nav"><div class="lp-wrap">
  <a class="lp-logo" href="/">Rumah Point</a>
  <div class="lp-navlinks">
    <a href="/dokumentasi">Dokumentasi model</a>
    <a href="/admin/login">Login admin</a>
  </div>
</div></nav>
<header class="lp-hero"><div class="lp-wrap lp-hero-grid">
  <div>
    <p class="lp-kicker">PBL Teknik Informatika Polinema, semester 5</p>
    <h1>Perkiraan harga rumah dari luas, kamar, dan lokasi.</h1>
    <p class="lp-lead">Aplikasi Android mengirim enam isian: luas tanah, luas bangunan,
       jumlah kamar, kamar mandi, kondisi bangunan, dan wilayah. Server menjalankan
       dua model Random Forest. Satu memperkirakan harga dalam Rupiah, satu menandai
       kategori Murah atau Mahal dibanding median wilayah.</p>
    <div class="lp-actions">
      <a class="lp-btn" href="/dokumentasi">Baca dokumentasi model</a>
      <a class="lp-link" href="#cara-kerja">Cara kerja</a>
    </div>
  </div>
  <aside class="lp-panel">
    <h2>Isian yang dibaca model</h2>
    <ol>
      <li>Luas tanah (m²)</li>
      <li>Luas bangunan (m²)</li>
      <li>Jumlah kamar tidur</li>
      <li>Jumlah kamar mandi</li>
      <li>Usia bangunan: baru atau bekas</li>
      <li>Provinsi dan kabupaten/kota</li>
    </ol>
    <p class="lp-note">Dataset gabungan berisi 64.650 baris dari 6 sumber. Sebelum
       pelatihan, 167 baris tidak masuk akal dibuang, sehingga model memakai 64.483 baris.</p>
  </aside>
</div></header>
<main>
<section class="lp-section" id="cara-kerja"><div class="lp-wrap lp-two">
  <div>
    <h2>Cara kerja</h2>
    <p>Semua perhitungan berjalan di server cloud. Aplikasi hanya mengirim isian
       ke endpoint <code>/predict</code> lalu menampilkan balasannya.</p>
  </div>
  <ol class="lp-steps">
    <li><span class="n">1</span><div><h3>Isi form</h3>
      <p>Masukkan luas tanah dan bangunan, jumlah kamar, kamar mandi, kondisi
         bangunan, lalu pilih wilayah.</p></div></li>
    <li><span class="n">2</span><div><h3>Kirim ke cloud</h3>
      <p>Aplikasi mengirim isian ke endpoint prediksi. Model regresi dan
         klasifikasi memakai satu pipeline yang sama.</p></div></li>
    <li><span class="n">3</span><div><h3>Baca hasil</h3>
      <p>Hasil berisi estimasi Rupiah, rentang indikatif, kategori pasar, dan
         peringatan bila data wilayah itu tipis.</p></div></li>
  </ol>
</div></section>
<section class="lp-section lp-section-alt"><div class="lp-wrap">
  <h2>Seberapa tepat prediksinya</h2>
  <p>Angka ini diukur pada {{ fakta.uji }} baris uji yang tersisa setelah baris mustahil
     dibuang. Model tidak selalu tepat, dan aplikasi menandai wilayah yang datanya
     kurang dari 100 baris.</p>
  <dl class="lp-facts">
    <div class="lp-fact"><dt>Galat setengah prediksi</dt><dd>≤ {{ fakta.p50 }}×</dd></div>
    <div class="lp-fact"><dt>Galat 9 dari 10 prediksi</dt><dd>≤ {{ fakta.p90 }}×</dd></div>
    <div class="lp-fact"><dt>Harga asli di dalam rentang ±25%</dt><dd>{{ fakta.pita }}%</dd></div>
    <div class="lp-fact"><dt>Wilayah dengan data cukup</dt><dd>{{ fakta.aman }} dari {{ fakta.entitas }}</dd></div>
  </dl>
  <p><a class="lp-link" href="/dokumentasi">Lihat metode, grafik, dan perbandingan model</a></p>
</div></section>
<section class="lp-section"><div class="lp-wrap lp-two">
  <div>
    <h2>Sumber data</h2>
    <p>Enam sumber digabung menjadi satu tabel. Angka di bawah adalah baris mentah
       sebelum penyaringan; rincian lisensi dan proses pembersihan ada di halaman
       dokumentasi.</p>
    <ul class="lp-sources">
      <li><span>FLUS komersial (Kaggle)</span><b>39.423</b></li>
      <li><span>99.co</span><b>14.352</b></li>
      <li><span>rumah123</span><b>8.824</b></li>
      <li><span>uas-properti (GitHub)</span><b>1.530</b></li>
      <li><span>Pinhome</span><b>321</b></li>
      <li><span>ColectDataRumah (GitHub)</span><b>200</b></li>
    </ul>
  </div>
  <aside class="lp-panel">
    <h2>Yang bisa diperiksa</h2>
    <ol>
      <li>Delapan grafik data, galat, dan perbandingan</li>
      <li>Perbandingan dengan tujuh model lain</li>
      <li>Hash artefak model dan versi pustaka</li>
      <li>Langkah regenerasi dokumen</li>
    </ol>
    <p class="lp-note"><a class="lp-link" href="/dokumentasi">Buka dokumentasi model</a></p>
  </aside>
</div></section>
<section class="lp-section lp-download" id="unduh"><div class="lp-wrap">
  <div>
    <h2>Aplikasi Android</h2>
    <p>APK belum dipublikasikan. Build saat ini dipakai untuk pengujian tim.
       Halaman ini menjelaskan model dan hasil pengukurannya.</p>
  </div>
  <span class="lp-status">Belum tersedia untuk publik</span>
</div></section>
</main>
<footer class="lp-footer"><div class="lp-wrap">
  <span>© 2026 Rumah Point. PBL Teknik Informatika Polinema.</span>
  <span><a href="/dokumentasi">Dokumentasi model</a> · <a href="/admin/login">Login admin</a></span>
</div></footer>
</body></html>"""

LOGIN = """<!doctype html>
<html lang="id"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Login Admin | Rumah Point</title>
<style>""" + STYLE + """</style></head><body>
<nav><div class="wrap">
  <a class="logo" href="/">Rumah Point</a>
  <a class="admin" href="/">← Beranda</a>
</div></nav>
<div class="login-card">
  <h2>Login Admin</h2>
  {% if error %}<p class="err">{{ error }}</p>{% endif %}
  <form method="post" action="/admin/login">
    <input type="password" name="password" placeholder="Kata sandi admin"
           required autofocus>
    <button type="submit">Masuk</button>
  </form>
</div>
</body></html>"""

PAGE = """<!doctype html>
<html lang="id"><head><meta charset="utf-8"><title>Rumah Point - Data Properti</title>
<style>
""" + STYLE + """
 table{border-collapse:collapse;width:100%;margin-top:16px}
 th,td{border:1px solid #ddd;padding:8px;text-align:left;font-size:14px}
 form.data{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;max-width:760px;
      padding:16px;border:1px solid #eee;border-radius:8px;background:#fff}
 label{font-size:13px} input,select{padding:6px}
 form.data button{padding:8px 14px;background:#00897b;color:#fff;border:0;border-radius:6px;cursor:pointer}
 .topbar{display:flex;justify-content:space-between;align-items:center}
</style></head><body>
<nav><div class="wrap">
  <a class="logo" href="/">Rumah Point</a>
  <a class="admin" href="/admin/logout">Logout</a>
</div></nav>
<div class="wrap" style="padding:24px 20px">
<div class="topbar">
  <h2 style="text-align:left;margin:0">Kelola Dataset Properti</h2>
  <span style="color:#888;font-size:13px">halaman internal tim</span>
</div>
<form method="post" action="/properti" class="data">
  <div><label>Lokasi</label><br><select name="lokasi">
    {% for c in cities %}<option>{{ c }}</option>{% endfor %}</select></div>
  <div><label>Luas (m2)</label><br><input name="luas_m2" type="number" step="0.1" required></div>
  <div><label>Luas Bangunan (m2, opsional)</label><br><input name="luas_bangunan" type="number" step="0.1"></div>
  <div><label>Kamar Tidur</label><br><input name="jumlah_kamar" type="number" required></div>
  <div><label>Kamar Mandi</label><br><input name="jumlah_kamar_mandi" type="number" required></div>
  <div><label>Usia Bangunan</label><br><input name="usia_bangunan" type="number" required></div>
  <div><label>Harga (Rp)</label><br><input name="harga" type="number" required></div>
  <div style="grid-column:1/4"><button type="submit">Tambah Data</button></div>
</form>
<h3>Total: {{ count }} baris</h3>
<table><tr><th>id</th><th>lokasi</th><th>luas</th><th>kt</th><th>km</th><th>usia</th><th>harga</th><th>kat</th><th></th></tr>
{% for r in rows %}<tr>
  <td>{{ r['id'] }}</td><td>{{ r['lokasi'] }}</td><td>{{ r['luas_m2'] }}</td>
  <td>{{ r['jumlah_kamar'] }}</td><td>{{ r['jumlah_kamar_mandi'] }}</td>
  <td>{{ r['usia_bangunan'] }}</td><td>{{ r['harga'] }}</td><td>{{ r['kategori_harga'] }}</td>
  <td><form method="post" action="/properti/{{ r['id'] }}/delete" style="display:inline">
     <button type="submit">hapus</button></form></td></tr>
{% endfor %}</table></div></body></html>"""


def rp(n):
    n = float(n)
    if n >= 1e12:
        return f"Rp {n/1e12:.2f} T"
    if n >= 1e9:
        return f"Rp {n/1e9:.2f} M"
    if n >= 1e6:
        return f"Rp {n/1e6:.1f} jt"
    return f"Rp {n:,.0f}"


DOK = """<!doctype html>
<html lang="id"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Dokumentasi Model | Rumah Point</title>
<style>""" + STYLE + """
 .doc section{padding:32px 0;border-top:1px solid #e2e8f0}
 .doc h1{margin:8px 0 4px}
 .doc h2{text-align:left;margin:0 0 18px;font-size:22px}
 .doc h3{margin:22px 0 10px;font-size:16px}
 .doc p,.doc li{line-height:1.65;color:#374151}
 .doc table{border-collapse:collapse;width:100%;margin:10px 0;font-size:13px;background:#fff}
 .doc th,.doc td{border:1px solid #e2e8f0;padding:8px;text-align:left;vertical-align:top}
 .doc th{background:#f1f5f9}
 .doc td.angka{text-align:right;font-variant-numeric:tabular-nums}
 .doc tr.pilih td{font-weight:600;background:#fffbeb}
 .doc .gulir{overflow-x:auto;margin:10px 0}
 .doc .gulir table{margin:0;min-width:560px}
 .doc img{max-width:100%;border:1px solid #e2e8f0;border-radius:8px;background:#fff;margin:8px 0}
 .doc .kartu{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin:16px 0}
 .doc .kartu div{background:#fff;border:1px solid #e2e8f0;border-radius:10px;padding:14px}
 .doc .kartu b{display:block;font-size:22px;color:#b45309}
 .doc .kartu span{font-size:12px;color:#64748b}
 .doc code{background:#f1f5f9;padding:2px 5px;border-radius:4px;font-size:12px}
 .doc .hash{font-family:ui-monospace,Consolas,monospace;font-size:11px;word-break:break-all}
 .doc ul{margin:8px 0 8px 18px;padding:0}
</style></head><body>
<nav><div class="wrap">
  <a class="logo" href="/">Rumah Point</a>
  <a class="admin" href="/">← Beranda</a>
</div></nav>
<div class="wrap doc" style="padding:24px 20px">
{% if dok is none %}
  <h1>Dokumentasi model belum tersedia</h1>
  <p>Jalankan <code>python ml/laporan.py</code> lalu muat ulang halaman ini.</p>
{% else %}
<h1>Dokumentasi Model</h1>
<p>Halaman ini <b>hanya membaca</b> artefak statis yang dibuat di luar web. Tidak ada
pelatihan atau praproses yang dijalankan di server. Dibuat pada
{{ dok.dibuat_pada[:16].replace('T', ' ') }} UTC.</p>
{% if segar is sameas false %}
<div class="err">Dokumentasi lebih lama dari database: dokumen mencatat
  {{ "{:,}".format(dok.provenance.jumlah_baris) }} baris, database sekarang
  {{ "{:,}".format(count) }} baris. Jalankan ulang <code>ml/laporan.py</code>.</div>
{% endif %}

<div class="kartu">
  <div><b>{{ "{:,}".format(dok.ringkasan.baris_mentah) }}</b><span>baris dataset</span></div>
  <div><b>{{ "{:,}".format(dok.ringkasan.baris_dilatih) }}</b><span>baris setelah filter ekor</span></div>
  <div><b>{{ "{:,}".format(dok.ringkasan.nama_lokasi) }}</b><span>kota kanonik</span></div>
  <div><b>{{ dok.ringkasan.klasifikasi_bersih.accuracy }}</b><span>akurasi klasifikasi (uji bersih)</span></div>
  <div><b>{{ dok.ringkasan.metrik_produksi_bersih.r2 }}</b><span>R² regresi (uji bersih)</span></div>
</div>

<section>
<h2>1. Ringkasan model</h2>
<p>Dua model Random Forest dilatih pada split yang sama: regresi harga (target
<code>log10(harga)</code>) dan klasifikasi kategori Murah/Mahal. Fitur:
luas tanah, luas bangunan, jumlah kamar, jumlah kamar mandi, usia bangunan, dan lokasi.</p>
<table>
<tr><th>Ukuran</th><th>Regresi harga</th><th>Klasifikasi kategori</th></tr>
<tr><td>MAE (baris uji bersih)</td>
  <td class="angka">{{ rp(dok.ringkasan.metrik_produksi_bersih.mae_rupiah) }}</td>
  <td>tidak dihitung</td></tr>
<tr><td>R² / akurasi</td>
  <td class="angka">{{ dok.ringkasan.metrik_produksi_bersih.r2 }}</td>
  <td class="angka">{{ dok.ringkasan.klasifikasi_bersih.accuracy }}</td></tr>
<tr><td>Jumlah baris uji</td>
  <td class="angka">{{ "{:,}".format(dok.ringkasan.metrik_produksi_bersih.n) }}</td>
  <td class="angka">{{ "{:,}".format(dok.ringkasan.klasifikasi_bersih.n) }}</td></tr>
<tr><td>Baris uji mustahil dibuang</td>
  <td colspan="2" class="angka">{{ dok.ringkasan.split_uji.n_uji_mustahil }}
      dari {{ "{:,}".format(dok.ringkasan.split_uji.n_uji) }} baris uji</td></tr>
</table>
<p>Split 80/20 dengan <code>random_state=42</code>;
{{ "{:,}".format(dok.ringkasan.split_uji.n_latih) }} latih /
{{ "{:,}".format(dok.ringkasan.split_uji.n_uji) }} uji. Angka penuh (sebelum baris
mustahil dibuang) tercatat di <code>ml/metrics.json</code>.</p>
</section>

<section>
<h2>2. Mengapa Random Forest</h2>
<ul>{% for a in dok.mengapa_rf.alasan %}<li>{{ a }}</li>{% endfor %}</ul>
<h3>Perbandingan regresi</h3>
<div class="gulir"><table>
<tr><th>Model</th><th>n latih</th><th>R²</th><th>MAE log10</th><th>MAE Rupiah</th><th>RMSE log10</th><th>Waktu latih</th></tr>
{% for m in dok.mengapa_rf.tabel|selectattr('tugas','equalto','regresi')|sort(attribute='metrik.r2') %}<tr{% if m.model == 'RandomForest' %} class="pilih"{% endif %}>
  <td>{{ m.model }}</td>
  <td class="angka">{{ "{:,}".format(m.n_latih) }}</td>
  <td class="angka">{{ m.metrik.r2 }}</td>
  <td class="angka">{{ m.metrik.mae_log10 }}</td>
  <td class="angka">{{ rp(m.metrik.mae_rupiah) }}</td>
  <td class="angka">{{ m.metrik.rmse_log10 }}</td>
  <td class="angka">{{ m.waktu_latih_detik }} s</td>
</tr>{% endfor %}
</table></div>
<h3>Perbandingan klasifikasi</h3>
<div class="gulir"><table>
<tr><th>Model</th><th>n latih</th><th>Akurasi</th><th>Presisi</th><th>Recall</th><th>F1</th><th>Waktu latih</th></tr>
{% for m in dok.mengapa_rf.tabel|selectattr('tugas','equalto','klasifikasi')|sort(attribute='metrik.accuracy') %}<tr{% if m.model == 'RandomForest' %} class="pilih"{% endif %}>
  <td>{{ m.model }}</td>
  <td class="angka">{{ "{:,}".format(m.n_latih) }}</td>
  <td class="angka">{{ m.metrik.accuracy }}</td>
  <td class="angka">{{ m.metrik.precision }}</td>
  <td class="angka">{{ m.metrik.recall }}</td>
  <td class="angka">{{ m.metrik.f1 }}</td>
  <td class="angka">{{ m.waktu_latih_detik }} s</td>
</tr>{% endfor %}
</table></div>
<p>Baris <b>RandomForest</b> yang disorot adalah konfigurasi produksi. SVR, SVC, dan KNN
memakai subsampel karena skala penuh tidak layak secara komputasi; jumlah baris latihnya
ada di kolom n latih, jadi waktu latih tidak sebanding langsung. Alasan tiap model ikut
diuji dicatat di berkas <code>docs/CATATAN-PERBANDINGAN-MODEL.md</code>.</p>
</section>

<section>
<h2>3. Data dan sumber</h2>
<p>Jumlah baris per sumber setelah 167 baris mustahil dibuang saat seed
(CSV gabungan berisi 64.650 baris).</p>
<table>
<tr><th>Sumber</th><th>Baris</th></tr>
{% for s in dok.data.sumber %}<tr><td>{{ s.sumber }}</td>
  <td class="angka">{{ "{:,}".format(s.baris) }}</td></tr>{% endfor %}
</table>
<h3>Cakupan wilayah</h3>
<p>{{ dok.data.cakupan.entitas_asset }} kabupaten/kota di aplikasi;
{{ dok.data.cakupan.aman_n_ge_100 }} punya ≥100 baris;
{{ dok.data.cakupan.belum_berdata }} belum berdata.</p>
<h3>Status lisensi</h3>
<table>
<tr><th>Sumber</th><th>Status</th></tr>
{% for l in dok.data.lisensi %}<tr><td>{{ l.sumber }}</td><td>{{ l.status }}</td></tr>{% endfor %}
</table>
<p>Keterangan lisensi dibuka apa adanya; sebagian sumber masih memerlukan
verifikasi sebelum dipakai di luar keperluan akademik.</p>
</section>

<section>
<h2>4. Jejak praproses</h2>
<table>
<tr><th>Langkah</th><th>Sebelum</th><th>Sesudah</th><th>Catatan</th></tr>
{% for p in dok.praproses %}<tr>
  <td>{{ p.langkah }}</td>
  <td class="angka">{{ "{:,}".format(p.sebelum) }}</td>
  <td class="angka">{{ "{:,}".format(p.sesudah) }}</td>
  <td>{{ p.catatan }}</td>
</tr>{% endfor %}
</table>
</section>

<section>
<h2>5. Visualisasi</h2>
{% for g in dok.grafik %}
  <h3>{{ g.judul }}</h3>
  <img src="/static/dokumentasi/{{ g.file }}" alt="{{ g.judul }}">
  <p>{{ g.keterangan }}</p>
{% endfor %}
</section>

<section>
<h2>6. Evaluasi jujur</h2>
<p>Setengah prediksi meleset ≤{{ dok.evaluasi_jujur.galat.p50 }}× harga asli;
75% ≤{{ dok.evaluasi_jujur.galat.p75 }}×; 90% ≤{{ dok.evaluasi_jujur.galat.p90 }}×.
Pita ±25% hanya menutup {{ dok.evaluasi_jujur.galat.pita_25_persen_tertutup }}% harga asli,
dan {{ dok.evaluasi_jujur.galat.persen_lebih_3x }}% prediksi meleset lebih dari 3×.</p>
<p>Dari {{ dok.evaluasi_jujur.kota.jumlah_kota_tabel }} wilayah yang bisa dihitung,
{{ dok.evaluasi_jujur.kota.kota_r2_negatif }} punya R² negatif pada set uji.
Model kalah dari rata-rata wilayah itu sendiri. Wilayah dengan sedikit data diberi
peringatan di aplikasi, bukan disembunyikan.</p>
</section>

<section>
<h2>7. Keterbatasan dan pembaruan</h2>
{% for k in dok.keterbatasan %}<h3>{{ k.judul }}</h3><p>{{ k.isi }}</p>{% endfor %}
<h3>Provenance</h3>
<table>
<tr><th>Objek</th><th>Nilai</th></tr>
<tr><td>sha256 price_regression.joblib</td><td class="hash">{{ dok.provenance.sha256_price_regression }}</td></tr>
<tr><td>sha256 kategori_classifier.joblib</td><td class="hash">{{ dok.provenance.sha256_kategori_classifier }}</td></tr>
<tr><td>sha256 meta.json</td><td class="hash">{{ dok.provenance.sha256_meta }}</td></tr>
<tr><td>md5 isi tabel properti</td><td class="hash">{{ dok.provenance.md5_tabel_properti }}</td></tr>
<tr><td>Versi</td><td>Python {{ dok.provenance.python }} · sklearn
  {{ dok.provenance.sklearn }} · numpy {{ dok.provenance.numpy }} · pandas
  {{ dok.provenance.pandas }} · joblib {{ dok.provenance.joblib }}</td></tr>
</table>
<p>Memperbarui: ubah data lewat panel admin, jalankan <code>database/seed.py</code> →
<code>ml/train.py</code> → <code>ml/build_wilayah.py</code> → <code>ml/perbandingan.py</code> →
<code>ml/laporan.py</code>, lalu unggah empat artefak model dan folder
<code>web/static/dokumentasi/</code> bersamaan.</p>
</section>
{% endif %}
</div>
</body></html>"""


@app.get("/")
def landing():
    # Angka di landing dibaca dari dokumentasi.json supaya tidak tertinggal saat model dilatih ulang.
    fakta = {"uji": "12.894", "p50": "1,18", "p90": "2,05", "pita": "62,62",
             "aman": "118", "entitas": "515"}
    if os.path.exists(DOK_JSON):
        with open(DOK_JSON, encoding="utf-8") as f:
            dok = json.load(f)
        g = dok["evaluasi_jujur"]["galat"]
        c = dok["data"]["cakupan"]
        fakta = {
            "uji": f"{dok['evaluasi_jujur']['uji_bersih']:,}".replace(",", "."),
            "p50": f"{g['p50']:.2f}".replace(".", ","),
            "p90": f"{g['p90']:.2f}".replace(".", ","),
            "pita": f"{g['pita_25_persen_tertutup']:.2f}".replace(".", ","),
            "aman": str(c["aman_n_ge_100"]),
            "entitas": str(c["entitas_asset"]),
        }
    return render_template_string(LANDING, fakta=fakta)


@app.get("/dokumentasi")
def dokumentasi():
    dok, segar, count = None, None, None
    if os.path.exists(DOK_JSON):
        with open(DOK_JSON, encoding="utf-8") as f:
            dok = json.load(f)
        try:
            con = db()
            count = con.execute("SELECT COUNT(*) c FROM properti").fetchone()["c"]
            con.close()
            segar = count == dok["provenance"]["jumlah_baris"]
        except sqlite3.Error:
            segar = None
    return render_template_string(DOK, dok=dok, segar=segar, count=count, rp=rp)


@app.get("/admin/login")
def login():
    if session.get("admin"):
        return redirect(url_for("index"))
    return render_template_string(LOGIN, error=None)


@app.post("/admin/login")
def login_post():
    password = request.form.get("password", "")
    if password and secrets.compare_digest(password, ADMIN_PASSWORD):
        session["admin"] = True
        return redirect(url_for("index"))
    time.sleep(0.5)
    return render_template_string(LOGIN, error="Kata sandi salah."), 401


@app.get("/admin/logout")
def logout():
    session.clear()
    return redirect(url_for("landing"))


@app.get("/admin")
@login_required
def index():
    con = db()
    rows = con.execute(
        "SELECT * FROM properti ORDER BY id DESC LIMIT 100").fetchall()
    count = con.execute("SELECT COUNT(*) c FROM properti").fetchone()["c"]
    cities = city_options(con)
    con.close()
    return render_template_string(PAGE, rows=rows, cities=cities, count=count)


@app.post("/properti")
@login_required
def create():
    data = request.form.to_dict() or (request.get_json(silent=True) or {})
    miss = required_fields(data)
    if miss:
        return jsonify({"error": "field hilang", "missing": miss}), 400
    harga = float(data["harga"])
    lb = data.get("luas_bangunan")
    lb = float(lb) if lb not in (None, "") else None
    con = db()
    cid = city_id_for(con, data["lokasi"])
    if cid is None:
        supported = ", ".join(city_options(con))
        con.close()
        return jsonify({"error": "kota tidak didukung", "didukung": supported}), 400
    nama_kota = con.execute(
        "SELECT nama FROM cities WHERE id=?", (cid,)).fetchone()["nama"]
    # kategori per-sentile: bandingkan harga dengan median kota kanonik
    med = con.execute(
        "SELECT harga FROM properti WHERE city_id=?", (cid,)).fetchall()
    kategori = data.get("kategori_harga")
    if not kategori:
        vals = sorted(r[0] for r in med)
        if vals:
            mid = len(vals) // 2
            m = vals[mid] if len(vals) % 2 else (vals[mid - 1] + vals[mid]) / 2
            kategori = "Mahal" if harga >= m else "Murah"
        else:
            kategori = None
    con.execute(
        "INSERT INTO properti (sumber, lokasi, city_id, luas_m2, luas_bangunan, jumlah_kamar,"
        " jumlah_kamar_mandi, usia_bangunan, harga, kategori_harga) VALUES (?,?,?,?,?,?,?,?,?,?)",
        ("manual-web", nama_kota, cid, float(data["luas_m2"]), lb,
         int(data["jumlah_kamar"]), int(data["jumlah_kamar_mandi"]),
         int(data["usia_bangunan"]), harga, kategori))
    con.commit()
    con.close()
    return redirect(url_for("index"))


@app.put("/api/properti/<int:pid>")
@login_required
def update(pid):
    data = request.get_json(silent=True) or {}
    fields = [k for k in ("lokasi", "luas_m2", "jumlah_kamar",
              "jumlah_kamar_mandi", "usia_bangunan", "harga", "kategori_harga") if k in data]
    if not fields:
        return jsonify({"error": "tidak ada field"}), 400
    if "lokasi" in data:
        con = db()
        cid = city_id_for(con, data["lokasi"])
        kota = con.execute(
            "SELECT nama FROM cities WHERE id=?", (cid,)).fetchone() if cid else None
        con.close()
        if cid is None or kota is None:
            return jsonify({"error": "kota tidak didukung"}), 400
        data["lokasi"] = kota["nama"]
        data["city_id"] = cid
        if "city_id" not in fields:
            fields.append("city_id")
    sets = ", ".join(f"{f}=?" for f in fields)
    vals = [data[f] for f in fields] + [pid]
    con = db()
    con.execute(f"UPDATE properti SET {sets} WHERE id=?", vals)
    con.commit()
    con.close()
    return jsonify({"updated": pid})


@app.post("/properti/<int:pid>/delete")
@app.delete("/api/properti/<int:pid>")
@login_required
def delete(pid):
    con = db()
    con.execute("DELETE FROM properti WHERE id=?", (pid,))
    con.commit()
    con.close()
    return redirect(url_for("index")) if request.form else jsonify({"deleted": pid})


@app.get("/api/properti")
@login_required
def list_json():
    con = db()
    rows = [dict(r) for r in con.execute(
        "SELECT * FROM properti ORDER BY id DESC LIMIT 500").fetchall()]
    con.close()
    return jsonify(rows)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")), debug=False)
