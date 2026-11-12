// Memperbaiki koordinat pusat kabupaten yang dobel dengan pusat kotanya.
// Cara: cari titik kisi paling "dalam" yang termuat poligon kabupaten tetapi
// tidak termuat poligon kota di dalamnya, lalu tulis sebagai pusat baru.
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '..');

const reg = JSON.parse(fs.readFileSync(path.join(ROOT, 'mobile/assets/data/batas.json'), 'utf8'));
const wil = JSON.parse(fs.readFileSync(path.join(ROOT, 'mobile/assets/data/wilayah.json'), 'utf8'));

function inRing(lng, lat, r) {
  let ins = false;
  for (let i = 0, j = r.length - 1; i < r.length; j = i++) {
    const [xi, yi] = r[i], [xj, yj] = r[j];
    if ((yi > lat) !== (yj > lat) && lng < ((xj - xi) * (lat - yi)) / (yj - yi) + xi) ins = !ins;
  }
  return ins;
}
const inPart = (lng, lat, p) => {
  if (!inRing(lng, lat, p[0])) return false;
  for (let i = 1; i < p.length; i++) if (inRing(lng, lat, p[i])) return false;
  return true;
};
const inReg = (lng, lat, r) => r.g.some((p) => inPart(lng, lat, p));
const bbox = (r) => {
  let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
  for (const p of r.g) for (const [x, y] of p[0]) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
  return [x0, y0, x1, y1];
};
// titik berat luas (shoelace) semua cincin luar
function areaCentroid(r) {
  let A = 0, cx = 0, cy = 0;
  for (const p of r.g) {
    const ring = p[0];
    let a = 0, x = 0, y = 0;
    for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      const f = ring[j][0] * ring[i][1] - ring[i][0] * ring[j][1];
      a += f; x += (ring[j][0] + ring[i][0]) * f; y += (ring[j][1] + ring[i][1]) * f;
    }
    a /= 2; if (a === 0) continue;
    A += a; cx += x / (6 * a) * a; cy += y / (6 * a) * a;
  }
  return A === 0 ? null : [cx / A, cy / A];
}

const changed = [];
for (const p of wil) for (const k of p.kabupatenKota) {
  const own = reg.find((r) => r.n === k.nama && r.p === p.nama);
  if (!own) continue;
  if (inReg(k.lng, k.lat, own)) continue; // sudah benar
  // kandidat: wilayah lain di provinsi sama yang memuat titik lama
  const penampung = reg.filter((r) => r.p === p.nama && r !== own && inReg(k.lng, k.lat, r));
  // titik baru: pusat luas, lalu carik titik kisi terdekat yang valid
  const c = areaCentroid(own);
  const target = c && inReg(c[0], c[1], own) && !penampung.some((r) => inReg(c[0], c[1], r))
    ? { lat: c[1], lng: c[0] }
    : null;
  let best = target;
  if (!best) {
    const [x0, y0, x1, y1] = bbox(own);
    const N = 60;
    for (let i = 0; i <= N; i++) for (let j = 0; j <= N; j++) {
      const lng = x0 + (x1 - x0) * (i + 0.5) / N, lat = y0 + (y1 - y0) * (j + 0.5) / N;
      if (!inReg(lng, lat, own)) continue;
      if (penampung.some((r) => inReg(lng, lat, r))) continue;
      const d = c ? Math.hypot(lng - c[0], lat - c[1]) : 0;
      if (!best || d < best.d) best = { lat, lng, d };
    }
  }
  if (!best) { console.log('TIDAK ADA TITIK:', p.nama, '/', k.nama); continue; }
  const lat = Math.round(best.lat * 1e5) / 1e5, lng = Math.round(best.lng * 1e5) / 1e5;
  changed.push(`${p.nama}/${k.nama}: ${k.lat},${k.lng} → ${lat},${lng}`);
  k.lat = lat; k.lng = lng;
}
console.log('diperbaiki:', changed.length);
for (const c of changed) console.log('  ', c);
fs.writeFileSync(path.join(ROOT, 'mobile/assets/data/wilayah.json'), JSON.stringify(wil));
