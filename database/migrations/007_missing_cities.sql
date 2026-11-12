-- 007_missing_cities: 24 nama lokasi yang sudah ada di properti tetapi belum
-- masuk cities. Sumber baris: Pinhome (321 baris) dan rumah123 (7 baris).
-- Nama disimpan persis seperti lokasi mentah agar city_id langsung terisi.
-- Penggabungan ejaan (mis. "Siak" dan "Kabupaten Siak") belum dilakukan di
-- sini; itu menunggu kebijakan alias berbasis city_id.
INSERT OR IGNORE INTO cities (nama, slug, provinsi) VALUES
    ('Aceh Barat Daya', 'aceh-barat-daya', 'Aceh'),
    ('Aceh Selatan', 'aceh-selatan', 'Aceh'),
    ('Aceh Tengah', 'aceh-tengah', 'Aceh'),
    ('Aceh Timur', 'aceh-timur', 'Aceh'),
    ('Alor', 'alor', 'Nusa Tenggara Timur'),
    ('Balangan', 'balangan', 'Kalimantan Selatan'),
    ('Banggai Laut', 'banggai-laut', 'Sulawesi Tengah'),
    ('Bangka Barat', 'bangka-barat', 'Kepulauan Bangka Belitung'),
    ('Bontang', 'bontang', 'Kalimantan Timur'),
    ('Buton Selatan', 'buton-selatan', 'Sulawesi Tenggara'),
    ('Halmahera Timur', 'halmahera-timur', 'Maluku Utara'),
    ('Kabupaten Kepulauan Anambas', 'kabupaten-kepulauan-anambas', 'Kepulauan Riau'),
    ('Kepahiang', 'kepahiang', 'Bengkulu'),
    ('Kepulauan Mentawai', 'kepulauan-mentawai', 'Sumatera Barat'),
    ('Kepulauan Meranti', 'kepulauan-meranti', 'Riau'),
    ('Mandailing Natal', 'mandailing-natal', 'Sumatera Utara'),
    ('Mesuji', 'mesuji', 'Lampung'),
    ('Musi Rawas', 'musi-rawas', 'Sumatera Selatan'),
    ('Nagan Raya', 'nagan-raya', 'Aceh'),
    ('Nias Selatan', 'nias-selatan', 'Sumatera Utara'),
    ('Rokan Hilir', 'rokan-hilir', 'Riau'),
    ('Seluma', 'seluma', 'Bengkulu'),
    ('Seram Bagian Timur', 'seram-bagian-timur', 'Maluku'),
    ('Siak', 'siak', 'Riau');
UPDATE properti SET city_id = (SELECT id FROM cities WHERE nama = properti.lokasi)
WHERE city_id IS NULL;
