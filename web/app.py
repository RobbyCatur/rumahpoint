
import os
import sqlite3

from flask import Flask, jsonify, redirect, render_template_string, request, url_for

BASE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE, "..", "database", "properti.db")
CITIES = ["Bogor", "Bekasi", "Depok", "Tangerang", "Jakarta Utara",
          "Jakarta Selatan", "Surabaya"]

app = Flask(__name__)


def db():
    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    return con


def required_fields(payload):
    req = ["lokasi", "luas_m2", "jumlah_kamar", "jumlah_kamar_mandi",
           "usia_bangunan", "harga"]
    return [k for k in req if payload.get(k) in (None, "")]


PAGE = """<!doctype html>
<html lang="id"><head><meta charset="utf-8"><title>Rumah Point - Data Properti</title>
<style>
 body{font-family:system-ui,Arial;margin:24px;color:#222}
 table{border-collapse:collapse;width:100%;margin-top:16px}
 th,td{border:1px solid #ddd;padding:8px;text-align:left;font-size:14px}
 form{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;max-width:760px;
      padding:16px;border:1px solid #eee;border-radius:8px}
 label{font-size:13px} input,select{padding:6px}
 button{padding:8px 14px;background:#00897b;color:#fff;border:0;border-radius:6px;cursor:pointer}
</style></head><body>
<h2>Rumah Point &mdash; Kelola Dataset Properti</h2>
<p>Halaman internal tim untuk menambah data latih (bukan untuk user akhir).</p>
<form method="post" action="/properti">
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
{% endfor %}</table></body></html>"""


@app.get("/")
def index():
    con = db()
    rows = con.execute(
        "SELECT * FROM properti ORDER BY id DESC LIMIT 100").fetchall()
    count = con.execute("SELECT COUNT(*) c FROM properti").fetchone()["c"]
    con.close()
    return render_template_string(PAGE, rows=rows, cities=CITIES, count=count)


@app.post("/properti")
def create():
    data = request.form.to_dict() or (request.get_json(silent=True) or {})
    miss = required_fields(data)
    if miss:
        return jsonify({"error": "field hilang", "missing": miss}), 400
    harga = float(data["harga"])
    lb = data.get("luas_bangunan")
    lb = float(lb) if lb not in (None, "") else None
    con = db()
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
        "INSERT INTO properti (sumber, lokasi, luas_m2, luas_bangunan, jumlah_kamar,"
        " jumlah_kamar_mandi, usia_bangunan, harga, kategori_harga) VALUES (?,?,?,?,?,?,?,?,?)",
        ("manual-web", data["lokasi"], float(data["luas_m2"]), lb,
         int(data["jumlah_kamar"]), int(data["jumlah_kamar_mandi"]),
         int(data["usia_bangunan"]), harga, kategori))
    con.commit()
    con.close()
    return redirect(url_for("index"))


@app.put("/api/properti/<int:pid>")
def update(pid):
    data = request.get_json(silent=True) or {}
    fields = [k for k in ("lokasi", "luas_m2", "jumlah_kamar",
              "jumlah_kamar_mandi", "usia_bangunan", "harga", "kategori_harga") if k in data]
    if not fields:
        return jsonify({"error": "tidak ada field"}), 400
    sets = ", ".join(f"{f}=?" for f in fields)
    vals = [data[f] for f in fields] + [pid]
    con = db()
    con.execute(f"UPDATE properti SET {sets} WHERE id=?", vals)
    con.commit()
    con.close()
    return jsonify({"updated": pid})


@app.post("/properti/<int:pid>/delete")
@app.delete("/api/properti/<int:pid>")
def delete(pid):
    con = db()
    con.execute("DELETE FROM properti WHERE id=?", (pid,))
    con.commit()
    con.close()
    return redirect(url_for("index")) if request.form else jsonify({"deleted": pid})


@app.get("/api/properti")
def list_json():
    con = db()
    rows = [dict(r) for r in con.execute(
        "SELECT * FROM properti ORDER BY id DESC LIMIT 500").fetchall()]
    con.close()
    return jsonify(rows)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")), debug=False)
