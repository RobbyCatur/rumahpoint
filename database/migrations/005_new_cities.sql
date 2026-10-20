-- 005: kota baru hasil perluasan Rute C (scrape 99.co, disetujui tim+dosen).
-- Backfill city_id untuk baris kota baru (002 hanya mengenal 7 kota awal).
INSERT OR IGNORE INTO cities (nama, slug, provinsi) VALUES
    ('Bandung', 'bandung', 'Jawa Barat'),
    ('Yogyakarta', 'yogyakarta', 'DI Yogyakarta'),
    ('Semarang', 'semarang', 'Jawa Tengah');
UPDATE properti SET city_id = (SELECT c.id FROM cities c WHERE c.nama = properti.lokasi)
    WHERE city_id IS NULL;
