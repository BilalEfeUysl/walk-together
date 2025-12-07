-- 1. KULLANICILAR (USERS) - En az 10 kayıt
-- Şifreler örnek olarak '12345' gibi düşünülmüştür, gerçekte hashlenir.
INSERT INTO users (username, password, role, total_points) VALUES
('admin_ahmet', 'admin123', 'admin', 1500),
('ayse_yurur', 'sifre1', 'user', 500),
('mehmet_kosar', 'sifre2', 'user', 850),
('zeynep_dagci', 'sifre3', 'user', 1200),
('can_trekking', 'sifre4', 'user', 300),
('elif_dogasever', 'sifre5', 'user', 0),
('burak_hizli', 'sifre6', 'user', 2100),
('selin_kamp', 'sifre7', 'user', 650),
('mert_yolcu', 'sifre8', 'user', 100),
('damla_gezgin', 'sifre9', 'user', 450),
('kerem_bisiklet', 'sifre10', 'user', 900),
('deniz_mavi', 'sifre11', 'user', 50);

-- 2. HOBİLER (USER_HOBBIES) - Kullanıcılarla ilişkili hobiler
INSERT INTO user_hobbies (user_id, hobby_name) VALUES
(1, 'Yürüyüş'), (1, 'Kamp'),
(2, 'Koşu'), (2, 'Pilates'),
(3, 'Maraton'), (3, 'Yüzme'),
(4, 'Tırmanış'), (4, 'Yürüyüş'),
(5, 'Bisiklet'),
(6, 'Yoga'),
(7, 'Ultra Maraton'), (7, 'Koşu'),
(8, 'Kamp'),
(9, 'Yürüyüş'),
(10, 'Fotoğrafçılık'), (10, 'Yürüyüş'),
(11, 'Bisiklet'), (11, 'Yüzme');

-- 3. ROTALAR (ROUTES) - En az 10 kayıt
-- Zorluk seviyeleri: Easy, Medium, Hard
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level) VALUES
(1, 'Belgrad Ormanı Büyük Tur', 6.5, 'Medium'),
(1, 'Caddebostan Sahil Yolu', 5.0, 'Easy'),
(3, 'Polonezköy Tabiat Parkı', 4.2, 'Medium'),
(4, 'Likya Yolu Başlangıç', 12.0, 'Hard'),
(2, 'Maçka Parkı Turu', 2.0, 'Easy'),
(7, 'Emirgan Korusu Yokuşu', 3.5, 'Hard'),
(5, 'Moda Sahili Yürüyüşü', 4.0, 'Easy'),
(3, 'Aydos Ormanı Zirve', 8.0, 'Hard'),
(8, 'Yıldız Parkı Gezisi', 2.5, 'Medium'),
(10, 'Büyükada Turu', 14.0, 'Hard'),
(2, 'Fenerbahçe Parkı', 1.5, 'Easy');

-- 4. DURAKLAR (STOPS) - Rotalara bağlı duraklar
-- route_id'lere dikkat ederek ekliyoruz
INSERT INTO stops (route_id, stop_order, location_name) VALUES
-- Belgrad Ormanı (Route 1)
(1, 1, 'Giriş Kapısı'), (1, 2, 'Neşet Suyu'), (1, 3, 'Üçgen Ev'),
-- Caddebostan (Route 2)
(2, 1, 'Dalyan Parkı'), (2, 2, 'Şaşkınbakkal'), (2, 3, 'Erenköy'),
-- Polonezköy (Route 3)
(3, 1, 'Köy Meydanı'), (3, 2, 'Yürüyüş Parkuru Başı'),
-- Likya Yolu (Route 4)
(4, 1, 'Ovacık Başlangıç'), (4, 2, 'Kirme Köyü'), (4, 3, 'Faralya'),
-- Maçka Parkı (Route 5)
(5, 1, 'Harbiye Girişi'), (5, 2, 'Teleferik Altı'),
-- Moda Sahili (Route 7)
(7, 1, 'İskele'), (7, 2, 'Kayalıklar'), (7, 3, 'Yoğurtçu Parkı'),
-- Büyükada (Route 10)
(10, 1, 'Saat Kulesi'), (10, 2, 'Lunapark Meydanı'), (10, 3, 'Aya Yorgi Yokuşu');

-- 5. ETKİNLİKLER (EVENTS) - En az 10 kayıt
-- status: 'active', 'completed', 'cancelled'
INSERT INTO events (organizer_id, route_id, event_date, status, description) VALUES
(2, 2, '2025-10-15 09:00:00', 'active', 'Hafta sonu sabah koşusu, herkes davetli!'),
(3, 1, '2025-10-16 08:00:00', 'active', 'Belgrad ormanında temiz hava yürüyüşü.'),
(4, 4, '2025-11-01 07:00:00', 'active', 'Profesyoneller için Likya etabı.'),
(1, 2, '2023-05-20 18:00:00', 'completed', 'Gün batımı yürüyüşü (Tamamlandı).'),
(5, 7, '2023-06-10 10:00:00', 'completed', 'Moda sahili kahve ve yürüyüş.'),
(7, 3, '2023-07-01 09:00:00', 'cancelled', 'Hava muhalefeti nedeniyle iptal.'),
(2, 5, '2025-10-20 17:00:00', 'active', 'Maçka parkında köpekli yürüyüş.'),
(8, 8, '2025-10-25 08:30:00', 'active', 'Aydos zirve tırmanışı.'),
(10, 10, '2025-11-05 09:00:00', 'active', 'Büyükada büyük tur bisiklet ve yürüyüş.'),
(1, 1, '2023-09-15 08:00:00', 'completed', 'Sonbahar başlangıcı yürüyüşü.');

-- 6. KATILIMLAR (PARTICIPATIONS) - Kullanıcıların etkinliklere katılımı
-- is_completed: true (tamamladı), false (henüz yapmadı veya tamamlayamadı)
INSERT INTO participations (user_id, event_id, is_completed) VALUES
(2, 1, false), -- Ayşe kendi etkinliğine katıldı
(3, 1, false), -- Mehmet de geliyor
(5, 1, false), -- Can da geliyor
(4, 2, false), -- Zeynep Belgrad turuna gidiyor
(7, 2, false),
(2, 4, true),  -- Tamamlanmış etkinlik
(3, 4, true),
(6, 4, true),
(8, 5, true),
(9, 5, false),
(11, 8, false),
(12, 9, false);