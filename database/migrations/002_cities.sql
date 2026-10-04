-- 002_cities: tabel induk kota + FK city_id pada properti (fase EXPAND).
-- Kolom `lokasi` lama TIDAK dihapus (kontrak di fase 003 setelah semua konsumen bermigrasi).
CREATE TABLE IF NOT EXISTS cities (
    id INTEGER PRIMARY KEY,
    nama TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    provinsi TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'aktif',
    alasan_eksklusi TEXT
);
INSERT OR IGNORE INTO cities (nama, slug, provinsi) VALUES
    ('Bekasi', 'bekasi', 'Jawa Barat'),
    ('Bogor', 'bogor', 'Jawa Barat'),
    ('Depok', 'depok', 'Jawa Barat'),
    ('Jakarta Selatan', 'jaksel', 'DKI Jakarta'),
    ('Jakarta Utara', 'jakut', 'DKI Jakarta'),
    ('Surabaya', 'surabaya', 'Jawa Timur'),
    ('Tangerang', 'tangerang', 'Banten');
ALTER TABLE properti ADD COLUMN city_id INTEGER REFERENCES cities(id);
UPDATE properti SET city_id = (SELECT c.id FROM cities c WHERE c.nama = properti.lokasi);
CREATE INDEX IF NOT EXISTS idx_properti_city ON properti(city_id);
