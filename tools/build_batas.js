// Membangun mobile/assets/data/batas.json dari geoBoundaries IDN ADM2
// (sumber: https://github.com/wmgeolab/geoBoundaries, lisensi ODCL).
// Struktur keluaran: [{n: nama, p: provinsi, g: [bagian..]}], tiap bagian =
// [cincian luar, ...lubang] berisi pasangan [lng, lat] hasil penyederhanaan.
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const EPS = Number(process.argv[2] || 0.0035); // toleransi simplificasi (derajat)

const wil = JSON.parse(fs.readFileSync(path.join(ROOT, 'mobile/assets/data/wilayah.json'), 'utf8'));
const topo = JSON.parse(fs.readFileSync(path.join(ROOT, 'tmp/ADM2.topojson'), 'utf8'));

// ── dekode topojson ────────────────────────────────────────────────
const [sx, sy] = topo.transform.scale, [tx, ty] = topo.transform.translate;
const base = topo.arcs.map((a) => { let x = 0, y = 0; return a.map(([dx, dy]) => { x += dx; y += dy; return [x, y]; }); });
const arcOf = (i) => (i < 0 ? base[~i].slice().reverse() : base[i]);
function ringOf(topoRing) {
  const pts = [];
  for (const i of topoRing) {
    const a = arcOf(i);
    pts.push(...(pts.length ? a.slice(1) : a));
  }
  return pts.map(([x, y]) => [x * sx + tx, y * sy + ty]);
}
const feats = topo.objects.IDNADM2gbOpen.geometries.map((g) => {
  const parts = g.type === 'Polygon' ? [g.arcs] : g.arcs;
  return { name: g.properties.shapeName, parts: parts.map((p) => p.map(ringOf)) };
});

// ── geometri dasar ─────────────────────────────────────────────────
function pointInRing(lng, lat, r) {
  let inside = false;
  for (let i = 0, j = r.length - 1; i < r.length; j = i++) {
    const [xi, yi] = r[i], [xj, yj] = r[j];
    if ((yi > lat) !== (yj > lat) && lng < ((xj - xi) * (lat - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}
// bagian[0] = luar, sisanya lubang
function pointInPart(lng, lat, part) {
  if (!pointInRing(lng, lat, part[0])) return false;
  for (let i = 1; i < part.length; i++) if (pointInRing(lng, lat, part[i])) return false;
  return true;
}
const inFeat = (lng, lat, f) => f.parts.some((p) => pointInPart(lng, lat, p));
function centroidOf(parts) {
  let sx2 = 0, sy2 = 0, n = 0;
  for (const p of parts) for (const [x, y] of p[0]) { sx2 += x; sy2 += y; n++; }
  return n ? [sx2 / n, sy2 / n] : null;
}

// ── pencocokan nama ────────────────────────────────────────────────
const strip = (s) => s.replace(/^(Kota |Kabupaten )/, '').trim();
const squish = (s) => s.toLowerCase().replace(/[^a-z]/g, '');
const ALIAS = {
  solo: 'surakarta', pasangkayu: 'pasangguaya', tojo: 'tojo una-una', toli: 'toli-toli',
  kepulanimtanimbar: 'Kepulauan Tanimbar',
};
const tipe = (s) => (/^Kota /.test(s) ? 'kota' : /^Kabupaten /.test(s) ? 'kab' : 'bare');
function matchEntry(k) {
  const kTipe = tipe(k.nama);
  // entri kota ("Kota X" / polos "X") → utamakan fitur "Kota X";
  // nama polos di geoBoundaries = kabupaten induknya.
  if (kTipe !== 'kab') {
    const targetKota = kTipe === 'kota' ? k.nama : 'Kota ' + k.nama;
    const ex = feats.filter((f) => f.name === targetKota);
    if (ex.length === 1) return ex[0];
  } else {
    const ex = feats.filter((f) => f.name === k.nama);
    if (ex.length === 1) return ex[0];
  }
  const target = squish(strip(k.nama));
  const samaNama = (f) =>
    squish(strip(f.name)) === target ||
    (ALIAS[target] || target) === (ALIAS[squish(strip(f.name))] || squish(strip(f.name)));
  // aturan: fitur "Kota …" = kota; fitur "Kabupaten …"/polos = kabupaten.
  // entri kota (berprefix "Kota " atau polos) → cari "Kota …" dulu;
  // bila tak ada, boleh kabupaten (mis. kasus nama unik ala Jakarta).
  const kotaKet = (f) => tipe(f.name) === 'kota';
  const kabKet = (f) => tipe(f.name) === 'kab' || tipe(f.name) === 'bare';
  const kotaUtama = kTipe === 'kota' || kTipe === 'bare';
  const sama = (f) => samaNama(f);
  let cand = feats.filter((f) => sama(f) && (kotaUtama ? kotaKet(f) : kabKet(f)));
  if (!cand.length) cand = feats.filter((f) => sama(f) && (kotaUtama ? kabKet(f) : kotaKet(f)));
  if (!cand.length) return null;
  const inside = cand.filter((f) => inFeat(k.lng, k.lat, f));
  if (inside.length === 1) return inside[0];
  const pool = inside.length ? inside : cand;
  pool.sort((a, b) => {
    const ca = centroidOf(a.parts), cb = centroidOf(b.parts);
    return Math.hypot(ca[0] - k.lng, ca[1] - k.lat) - Math.hypot(cb[0] - k.lng, cb[1] - k.lat);
  });
  const c = centroidOf(pool[0].parts);
  return c && Math.hypot(c[0] - k.lng, c[1] - k.lat) <= 1.5 ? pool[0] : null;
}

// ── penyederhanaan Douglas-Peucker ─────────────────────────────────
function perpDist([x, y], [ax, ay], [bx, by]) {
  const dx = bx - ax, dy = by - ay, L2 = dx * dx + dy * dy;
  if (L2 === 0) return Math.hypot(x - ax, y - ay);
  const t = Math.max(0, Math.min(1, ((x - ax) * dx + (y - ay) * dy) / L2));
  return Math.hypot(x - (ax + t * dx), y - (ay + t * dy));
}
function dp(ring, eps) {
  if (ring.length < 3) return ring;
  let maxD = 0, idx = 0;
  const a = ring[0], b = ring[ring.length - 1];
  for (let i = 1; i < ring.length - 1; i++) { const d = perpDist(ring[i], a, b); if (d > maxD) { maxD = d; idx = i; } }
  if (maxD > eps) { const l = dp(ring.slice(0, idx + 1), eps), r = dp(ring.slice(idx), eps); return l.slice(0, -1).concat(r); }
  return [a, b];
}
const ringArea = (r) => { let a = 0; for (let i = 0, j = r.length - 1; i < r.length; j = i++) a += r[j][0] * r[i][1] - r[i][0] * r[j][1]; return Math.abs(a / 2); };
const R3 = (v) => Math.round(v * 1000) / 1000;
function simplifyFeat(f) {
  const parts = [];
  for (const p of f.parts) {
    const outer = p[0].length > 8 ? dp(p[0], EPS) : p[0];
    if (outer.length < 4 || ringArea(outer) < 0.00003) continue;
    const rings = [outer];
    for (const h of p.slice(1)) { const s = h.length > 8 ? dp(h, EPS) : h; if (s.length >= 4 && ringArea(s) >= 0.00003) rings.push(s); }
    parts.push(rings.map((r) => r.map(([x, y]) => [R3(x), R3(y)])));
  }
  return parts.length ? parts : null;
}

// ── jalankan ───────────────────────────────────────────────────────
const regions = [], gagal = [], geser = [];
for (const p of wil) for (const k of p.kabupatenKota) {
  const m = matchEntry(k);
  if (!m) { gagal.push(`${p.nama} / ${k.nama}`); continue; }
  const g = simplifyFeat(m);
  if (!g) { gagal.push(`${p.nama} / ${k.nama} (geometri)`); continue; }
  // validasi: pusat resmi harus tetap termuat setelah disederhanakan
  if (!g.some((part) => pointInPart(k.lng, k.lat, part))) geser.push(`${p.nama} / ${k.nama}`);
  regions.push({ n: k.nama, p: p.nama, g });
}
console.log('eps=' + EPS, '| ber-poligon:', regions.length, '/ 515 | gagal:', gagal.length, '| pusat keluar poligon:', geser.length);
if (gagal.length) console.log('gagal:', gagal.join(' | '));
if (geser.length) console.log('geser:', geser.slice(0, 12).join(' | '));

// ── uji titik terkenal (pada keluaran jadi) ────────────────────────
const tests = [
  ['Kota Malang (Balai Kota)', -7.9666, 112.6326, 'Malang'],
  ['Kab. Malang (Kepanjen)', -8.1037, 112.5675, 'Kabupaten Malang'],
  ['Kota Batu', -7.8610, 112.5230, 'Batu'],
  ['Kota Bekasi', -6.2383, 106.9756, 'Bekasi'],
  ['Kab. Bekasi (Cikarang)', -6.3100, 107.1000, 'Kabupaten Bekasi'],
  ['Kota Bandung', -6.9175, 107.6191, 'Bandung'],
  ['Kab. Bandung (Soreang)', -7.0360, 107.6200, 'Kabupaten Bandung'],
  ['Jakarta Selatan', -6.2800, 106.8100, 'Jakarta Selatan'],
  ['Kota Surabaya (Gubeng)', -7.2580, 112.7450, 'Surabaya'],
  ['Kab. Tangerang (Tigaraksa)', -6.2700, 106.5400, 'Kabupaten Tangerang'],
  ['Kota Tangerang', -6.1783, 106.6319, 'Tangerang'],
  ['Banjarmasin (Kalsel)', -3.3180, 114.5900, 'Banjarmasin'],
  ['Kab. Serang (Pandeglang-ish)', -6.1100, 106.0700, 'Kabupaten Serang'],
  ['Kota Serang', -6.0230, 106.1480, 'Serang'],
];
let pass = 0;
for (const [label, lat, lng, ingin] of tests) {
  const hit = regions.filter((r) => r.g.some((part) => pointInPart(lng, lat, part)));
  const ok = hit.length === 1 && hit[0].n === ingin;
  if (ok) pass++;
  console.log(ok ? 'OK  ' : 'GAGAT', label, '→', hit.map((h) => h.n).join(',') || '(kosong)', ok ? '' : `(harapan: ${ingin})`);
}
console.log('uji:', pass + '/' + tests.length);

const out = JSON.stringify(regions);
fs.writeFileSync(path.join(ROOT, 'mobile/assets/data/batas.json'), out);
console.log('ukuran:', (out.length / 1048576).toFixed(2), 'MB');
