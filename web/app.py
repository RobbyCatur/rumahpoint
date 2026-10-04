
import os
import secrets
import sqlite3
import time
from functools import wraps

from flask import (Flask, jsonify, redirect, render_template_string, request,
                   session, url_for)

BASE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE, "..", "database", "properti.db")

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
<title>Rumah Point — Prediksi Harga Rumah</title>
<style>""" + STYLE + """</style></head><body>
<nav><div class="wrap">
  <a class="logo" href="/">Rumah Point</a>
  <a class="admin" href="/admin/login">Login Admin</a>
</div></nav>
<div class="hero">
  <h1>Perkiraan harga rumah dalam hitungan detik</h1>
  <p>Rumah Point membantu calon pembeli dan penjual menaksir harga rumah di 7 kota
     Indonesia dari atributnya — luas, jumlah kamar, usia bangunan, dan lokasi —
     dengan model machine learning di cloud.</p>
  <a class="btn" href="#unduh">Coba Aplikasi Mobile</a>
</div>
<div class="stats">
  <div class="stat"><b>7</b><span>Kota didukung</span></div>
  <div class="stat"><b>3.730</b><span>Data latih properti</span></div>
  <div class="stat"><b>R² 0,85</b><span>Akurasi regresi harga</span></div>
  <div class="stat"><b>93,3%</b><span>Akurasi klasifikasi kategori</span></div>
</div>
<section class="wrap">
  <h2>Cara Kerja</h2>
  <div class="cards">
    <div class="card"><span class="num">1</span><h3>Isi Form</h3>
      <p>Masukkan atribut rumah: luas tanah &amp; bangunan, jumlah kamar dan kamar mandi,
         usia bangunan, serta pilih kota.</p></div>
    <div class="card"><span class="num">2</span><h3>Cloud ML Memproses</h3>
      <p>Aplikasi mengirim data ke layanan cloud yang menjalankan model
         RandomForest (regresi + klasifikasi).</p></div>
    <div class="card"><span class="num">3</span><h3>Hasil &amp; Kategori</h3>
      <p>Dapatkan estimasi harga, rentang indikatif ±25%, kategori Murah/Mahal
         di pasar kotanya, plus rekomendasi singkat.</p></div>
  </div>
</section>
<section class="wrap" style="padding-top:0">
  <h2>Fitur</h2>
  <div class="cards">
    <div class="card"><h3>Estimasi Harga</h3><p>Regresi harga dalam Rupiah dengan rentang indikatif.</p></div>
    <div class="card"><h3>Kategori Pasar</h3><p>Murah atau Mahal, relatif terhadap median kota tersebut.</p></div>
    <div class="card"><h3>Riwayat Analisis</h3><p>Simpan dan telusuri hasil prediksi (fitur akun — segera).</p></div>
    <div class="card"><h3>Panel Admin</h3><p>Tim mengelola dataset properti dan melatih ulang model.</p></div>
  </div>
</section>
<section class="wrap" id="unduh" style="padding-top:0">
  <h2>Unduh</h2>
  <div class="cards"><div class="card"><h3>Aplikasi Android</h3>
    <p>APK Rumah Point — segera tersedia. Pertanyaan tim:
       <b>PBL Teknik Informatika Polinema</b>.</p></div></div>
</section>
<footer>© 2026 Rumah Point — PBL Teknik Informatika Polinema Semester 5 ·
 <a href="/admin/login" style="color:#00897b">Login Admin</a></footer>
</body></html>"""

LOGIN = """<!doctype html>
<html lang="id"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Login Admin — Rumah Point</title>
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


@app.get("/")
def landing():
    return render_template_string(LANDING)


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
    # kategori per-sentile: bandingkan harga dengan median kota ini di DB
    med = con.execute(
        "SELECT harga FROM properti WHERE lokasi=?", (data["lokasi"],)).fetchall()
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
        ("manual-web", data["lokasi"], cid, float(data["luas_m2"]), lb,
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
        con.close()
        if cid is None:
            return jsonify({"error": "kota tidak didukung"}), 400
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
