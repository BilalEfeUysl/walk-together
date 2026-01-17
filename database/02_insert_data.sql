-- ==========================================
-- 02_insert_data.sql
-- ADIM 1: SABİT VERİLER VE KULLANICILAR (Tüm tablolar 10+ Kayıt)
-- ==========================================

-- 1. HOBİLER (12 Kayıt)
INSERT INTO hobbies (hobby_name, icon) VALUES 
('Doğa Yürüyüşü', 'fas fa-hiking'), ('Kamp', 'fas fa-campground'),
('Fotoğrafçılık', 'fas fa-camera'), ('Bisiklet', 'fas fa-bicycle'),
('Koşu', 'fas fa-running'), ('Yüzme', 'fas fa-swimmer'),
('Yoga', 'fas fa-spa'), ('Müzik', 'fas fa-music'),
('Resim', 'fas fa-palette'), ('Kitap', 'fas fa-book'),
('Oyun', 'fas fa-gamepad'), ('Yemek', 'fas fa-utensils')
ON CONFLICT DO NOTHING;

-- 2. KATEGORİLER (10 Kayıt)
INSERT INTO categories (category_name, icon_url) VALUES
('Doğa Yürüyüşü', 'fas fa-tree'), ('Şehir Turu', 'fas fa-city'), 
('Gece Yürüyüşü', 'fas fa-moon'), ('Bisiklet Turu', 'fas fa-bicycle'), 
('Profesyonel Tırmanış', 'fas fa-mountain'), ('Köpek Gezdirme', 'fas fa-dog'),
('Kanyon Geçişi', 'fas fa-water'), ('Kuş Gözlemi', 'fas fa-dove'), 
('Fotoğraf Safarisi', 'fas fa-camera'), ('Kültür Gezisi', 'fas fa-landmark');

-- 3. RÜTBELER (11 Kayıt)
INSERT INTO ranks (name, min_points, color_class) VALUES 
('Yeni Başlayan', 0, 'bg-slate-100 text-slate-600 border-slate-200'),
('Hevesli Yürüyüşçü', 50, 'bg-slate-200 text-slate-700 border-slate-300'),
('Çırak', 150, 'bg-zinc-100 text-zinc-700 border-zinc-200'),
('Tecrübeli', 300, 'bg-yellow-100 text-yellow-700 border-yellow-200'),
('Bronz Gezgin', 500, 'bg-orange-100 text-orange-700 border-orange-200'),
('Gümüş Rota', 750, 'bg-gray-200 text-gray-800 border-gray-400'),
('Altın Adımlar', 1000, 'bg-yellow-200 text-yellow-800 border-yellow-400'),
('Usta Kâşif', 1500, 'bg-blue-100 text-blue-700 border-blue-200'),
('Zirve Ortağı', 2000, 'bg-indigo-100 text-indigo-700 border-indigo-200'),
('Efsane', 3000, 'bg-purple-100 text-purple-700 border-purple-200'),
('Doğa Lideri', 5000, 'bg-red-100 text-red-700 border-red-200');

-- 4. ROZETLER (11 Kayıt)
INSERT INTO badges (badge_name, description, badge_type, required_value, icon_url) VALUES
('İlk Adım', 'İlk etkinliğine katıldı.', 'User', 1, 'fas fa-hiking'),
('Bronz Seviye', 'Toplam 500 puana ulaştı.', 'User', 500, 'fas fa-shoe-prints'),
('Gümüş Seviye', 'Toplam 1000 puana ulaştı.', 'User', 1000, 'fas fa-medal'),
('Altın Seviye', 'Toplam 1500 puana ulaştı.', 'User', 1500, 'fas fa-trophy'),
('Maratoncu', 'Toplam 2000 puana ulaştı.', 'User', 2000, 'fas fa-running'),
('Sosyal Kelebek', '10 arkadaşa ulaştı.', 'User', 10, 'fas fa-users'),
('Popüler', '20 arkadaşa ulaştı.', 'User', 20, 'fas fa-star'),
('Lider Ruh', 'Bir kulüp kurdu.', 'User', 0, 'fas fa-crown'),
('Fotoğrafçı', 'Etkinliklerde fotoğraf paylaştı.', 'User', 0, 'fas fa-camera'),
('Gece Kuşu', 'Gece etkinliğine katıldı.', 'User', 0, 'fas fa-moon'),
('Erkenci Kuş', 'Sabah etkinliğine katıldı.', 'User', 0, 'fas fa-sun');

-- 5. KULLANICILAR (15 Kayıt)
INSERT INTO users (username, password, role, total_points, profile_picture_url, bio, gender, birth_date, city) VALUES
('admin_ahmet', 'admin123', 'admin', 2500, 'https://ui-avatars.com/api/?name=Admin+Ahmet&background=random', 'Sistem Yöneticisi.', 'Male', '1990-05-15', 'İstanbul'),
('ayse_yurur', '1234', 'user', 500, 'https://ui-avatars.com/api/?name=Ayse+Yurur&background=random', 'Doğa aşığı.', 'Female', '1998-03-22', 'İstanbul'),
('mehmet_kosar', '1234', 'user', 850, NULL, 'Koşucu.', 'Male', '1995-11-10', 'Ankara'),
('zeynep_dagci', '1234', 'user', 1200, 'https://ui-avatars.com/api/?name=Zeynep+Dagci&background=random', 'Zirveci.', 'Female', '2000-01-30', 'İzmir'),
('can_trekking', '1234', 'user', 300, NULL, 'Acemi.', 'Male', '2003-07-14', 'Bursa'),
('elif_dogasever', '1234', 'user', 50, 'https://ui-avatars.com/api/?name=Elif+Dogasever&background=random', 'Huzur.', 'Female', '1999-09-09', 'İstanbul'),
('burak_hizli', '1234', 'user', 2100, NULL, 'Hız.', 'Male', '1992-12-05', 'Antalya'),
('selin_kamp', '1234', 'user', 650, 'https://ui-avatars.com/api/?name=Selin+Kamp&background=random', 'Kampçı.', 'Female', '2001-06-18', 'Muğla'),
('mert_yolcu', '1234', 'user', 100, NULL, NULL, 'Unspecified', '1997-02-14', 'İstanbul'),
('damla_gezgin', '1234', 'user', 450, 'https://ui-avatars.com/api/?name=Damla+Gezgin&background=random', 'Gezgin.', 'Female', '1996-08-30', 'İzmir'),
('kerem_bisiklet', '1234', 'user', 900, NULL, 'Bisikletçi.', 'Male', '1994-04-25', 'İstanbul'),
('deniz_mavi', '1234', 'user', 0, NULL, NULL, 'Unspecified', '2002-10-10', 'Ankara'),
('ozan_kaptan', '1234', 'user', 1600, 'https://ui-avatars.com/api/?name=Ozan+Kaptan&background=random', 'Rota Uzmanı.', 'Male', '1989-11-20', 'Çanakkale'),
('pinar_yoga', '1234', 'user', 250, NULL, 'Namaste.', 'Female', '1995-05-05', 'İstanbul'),
('emre_tirmans', '1234', 'user', 1800, NULL, 'Tırmanış.', 'Male', '1993-01-15', 'Antalya');

-- 6. KULLANICI HOBİLERİ (20 Kayıt)
INSERT INTO user_hobbies (user_id, hobby_id) VALUES
(1,1), (1,2), (1,3), (2,1), (2,7), (3,5), (3,4), (4,1), (4,2), (4,5),
(7,4), (7,5), (8,2), (8,3), (11,4), (11,2), (13,1), (13,10), (14,7), (14,1);

-- 7. ARKADAŞLIKLAR (14 Kayıt)
INSERT INTO friendships (requester_id, addressee_id, status) VALUES
(1, 2, 'accepted'), (1, 3, 'pending'), (2, 4, 'accepted'), (2, 8, 'accepted'),
(3, 7, 'accepted'), (3, 5, 'pending'), (4, 13, 'accepted'), (4, 15, 'accepted'),
(7, 11, 'accepted'), (7, 1, 'pending'), (8, 2, 'pending'), (8, 14, 'accepted'),
(13, 1, 'accepted'), (15, 4, 'pending');

-- ==========================================
-- ADIM 2: ROTALAR VE DURAKLAR (Mantıksal Bloklar Halinde)
-- (12 Rota, 30+ Durak)
-- ==========================================

-- ROTA 1: BELGRAD ORMANI (Kullanıcı ID: 2 - Ayşe)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (2, 'Belgrad Ormanı Büyük Tur', 6.5, 'Medium', 90);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(1, 1, 'Giriş Kapısı', 41.1793, 28.9698),
(1, 2, 'Neşet Suyu', 41.1856, 28.9567),
(1, 3, 'Üçgen Ev', 41.1920, 28.9480);

-- ROTA 2: CADDEBOSTAN SAHİL (Kullanıcı ID: 11 - Kerem)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (11, 'Caddebostan Sahil Yolu', 5.0, 'Easy', 60);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(2, 1, 'Dalyan Parkı', 40.9667, 29.0531),
(2, 2, 'Şaşkınbakkal', 40.9632, 29.0685),
(2, 3, 'Erenköy', 40.9605, 29.0801);

-- ROTA 3: POLONEZKÖY (Kullanıcı ID: 3 - Mehmet)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (3, 'Polonezköy Tabiat Parkı', 4.2, 'Medium', 75);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(3, 1, 'Köy Meydanı', 41.1123, 29.2105),
(3, 2, 'Yürüyüş Parkuru Başı', 41.1145, 29.2150);

-- ROTA 4: LİKYA YOLU (Kullanıcı ID: 13 - Ozan)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (13, 'Likya Yolu Başlangıç', 12.0, 'Hard', 240);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(4, 1, 'Ovacık Başlangıç', 36.5705, 29.1550),
(4, 2, 'Kirme Köyü', 36.5450, 29.1320),
(4, 3, 'Faralya', 36.5012, 29.1285);

-- ROTA 5: MAÇKA PARKI (Kullanıcı ID: 6 - Elif)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (6, 'Maçka Parkı Turu', 2.0, 'Easy', 30);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(5, 1, 'Harbiye Girişi', 41.0450, 28.9915),
(5, 2, 'Teleferik Altı', 41.0425, 28.9940);

-- ROTA 6: EMİRGAN KORUSU (Kullanıcı ID: 7 - Burak)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (7, 'Emirgan Korusu Yokuşu', 3.5, 'Hard', 50);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(6, 1, 'Sahil Girişi', 41.1085, 29.0550),
(6, 2, 'Beyaz Köşk', 41.1100, 29.0570),
(6, 3, 'Sarı Köşk', 41.1120, 29.0590);

-- ROTA 7: MODA SAHİLİ (Kullanıcı ID: 14 - Pınar)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (14, 'Moda Sahili Yürüyüşü', 4.0, 'Easy', 45);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(7, 1, 'İskele', 40.9850, 29.0250),
(7, 2, 'Kayalıklar', 40.9820, 29.0280),
(7, 3, 'Yoğurtçu Parkı', 40.9850, 29.0300);

-- ROTA 8: AYDOS ORMANI (Kullanıcı ID: 4 - Zeynep)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (4, 'Aydos Ormanı Zirve', 8.0, 'Hard', 150);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(8, 1, 'Gölet Girişi', 40.9250, 29.2500),
(8, 2, 'Orta Bölge', 40.9300, 29.2550),
(8, 3, 'Aydos Kalesi', 40.9350, 29.2600);

-- ROTA 9: YILDIZ PARKI (Kullanıcı ID: 1 - Admin)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (1, 'Yıldız Parkı Gezisi', 2.5, 'Medium', 40);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(9, 1, 'Çırağan Girişi', 41.0450, 29.0150),
(9, 2, 'Şale Köşkü', 41.0500, 29.0120);

-- ROTA 10: BÜYÜKADA (Kullanıcı ID: 10 - Damla)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (10, 'Büyükada Turu', 14.0, 'Hard', 300);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(10, 1, 'Saat Kulesi', 40.8755, 29.1275),
(10, 2, 'Lunapark Meydanı', 40.8650, 29.1180),
(10, 3, 'Aya Yorgi Yokuşu', 40.8600, 29.1150);

-- ROTA 11: FENERBAHÇE PARKI (Kullanıcı ID: 5 - Can)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (5, 'Fenerbahçe Parkı', 1.5, 'Easy', 25);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(11, 1, 'Giriş', 40.9680, 29.0350),
(11, 2, 'Deniz Feneri', 40.9650, 29.0320);

-- ROTA 12: ANTALYA KONYAALTI (Kullanıcı ID: 15 - Emre)
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
VALUES (15, 'Konyaaltı Sahil Koşusu', 7.0, 'Medium', 80);

INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(12, 1, 'Müze Önü', 36.8850, 30.6800),
(12, 2, 'Beach Park', 36.8800, 30.6700),
(12, 3, 'Liman', 36.8500, 30.6200);


-- ==========================================
-- ADIM 3: KULÜPLER, ETKİNLİKLER VE DİĞERLERİ
-- ==========================================

-- 8. KULÜPLER (11 Kayıt - Sequence Kullanımı)
INSERT INTO clubs (club_name, description, owner_id, club_image_url) VALUES
('YTÜ Doğa Kulübü', 'Yıldız Teknik öğrencileri için doğa gezileri.', 1, 'https://loremflickr.com/500/300/nature'),
('İstanbul Maratoncuları', 'Her pazar sabahı koşuyoruz.', 3, 'https://loremflickr.com/500/300/running'),
('Gece Kartalları', 'Şehri gece keşfediyoruz.', 7, 'https://loremflickr.com/500/300/night'),
('Ankara Yürüyüş', 'Başkent sokakları.', 3, 'https://loremflickr.com/500/300/walking'),
('İzmir Kordon', 'Sahil yürüyüşleri.', 4, 'https://loremflickr.com/500/300/sea'),
('Kamp Ateşi', 'Sadece kamp sevenler.', 8, 'https://loremflickr.com/500/300/fire'),
('Bisiklet Kardeşliği', 'Pedallayanlar buraya.', 11, 'https://loremflickr.com/500/300/bicycle'),
('Bursa Dağcıları', 'Uludağ tırmanış ekibi.', 5, 'https://loremflickr.com/500/300/mountain'),
('Karadeniz Fırtınası', 'Yaylaları geziyoruz.', 2, 'https://loremflickr.com/500/300/forest'),
('Antalya Trekking', 'Likya yolu yolcuları.', 15, 'https://loremflickr.com/500/300/hiking'),
('Fotoğraf Avcıları', 'En güzel manzaraları yakalıyoruz.', 1, 'https://loremflickr.com/500/300/camera');

-- 9. KULÜP ÜYELERİ (Composite PK - Önce Başkanlar, Sonra Üyeler)
-- Başkanlar (Admin)
INSERT INTO club_members (club_id, user_id, role) VALUES
(1, 1, 'admin'), (2, 3, 'admin'), (3, 7, 'admin'), (4, 3, 'admin'),
(5, 4, 'admin'), (6, 8, 'admin'), (7, 11, 'admin'), (8, 5, 'admin'),
(9, 2, 'admin'), (10, 15, 'admin'), (11, 1, 'admin');

-- Üyeler (Member) - Rastgele Dağıtım
INSERT INTO club_members (club_id, user_id, role) VALUES
(1, 2, 'member'), (1, 4, 'member'), (1, 6, 'member'),
(2, 7, 'member'), (2, 11, 'member'), (2, 1, 'member'),
(3, 5, 'member'), (3, 2, 'member'), (3, 10, 'member'),
(6, 1, 'member'), (6, 4, 'member'), (7, 3, 'member'),
(10, 13, 'member'), (10, 4, 'member'), (10, 8, 'member');

-- 10. KULÜP DUYURULARI (12 Kayıt)
INSERT INTO club_announcements (club_id, sender_id, message) VALUES
(1, 1, 'Hafta sonu etkinlik iptal.'), (1, 1, 'Yeni rota eklendi.'),
(2, 3, 'Pazar sabahı 06:00 toplanma.'), (2, 3, 'Forma siparişleri geldi.'),
(3, 7, 'Gece yürüyüşü için fener almayı unutmayın.'),
(1, 2, 'Aidatlar hakkında bilgilendirme.'), (6, 8, 'Kamp alanı değişti!'),
(2, 7, 'Katılım listesi doldu.'), (10, 15, 'Hava durumu yağmurlu görünüyor.'),
(3, 7, 'Bir sonraki rota önerilerinizi bekliyorum.'),
(7, 11, 'Lastik tamir kiti getirin.'), (5, 4, 'Kordon boyunda buluşuyoruz.');

-- 11. ETKİNLİKLER (15 Kayıt - Geçmiş ve Gelecek Karışık)
-- Tarihleri NOW() üzerinden dinamik ayarlıyoruz ki her zaman mantıklı olsun.
INSERT INTO events (organizer_id, route_id, category_id, event_date, status, title, description, max_participants, deadline) VALUES
-- Gelecek Etkinlikler (Active / Upcoming)
(2, 1, 1, NOW() + INTERVAL '5 days', 'active', 'Belgrad Sabah Yürüyüşü', 'Sabah temiz hava.', 20, NOW() + INTERVAL '4 days'),
(11, 2, 4, NOW() + INTERVAL '2 days', 'active', 'Caddebostan Bisiklet Turu', 'Sahil şeridi turu.', 15, NOW() + INTERVAL '1 day'),
(3, 3, 1, NOW() + INTERVAL '10 days', 'upcoming', 'Polonezköy Kaçamağı', 'Hafta sonu etkinliği.', 30, NOW() + INTERVAL '8 days'),
(13, 4, 1, NOW() + INTERVAL '20 days', 'upcoming', 'Likya Başlangıç Etabı', 'Zorlu parkur.', 10, NOW() + INTERVAL '15 days'),
(6, 5, 2, NOW() + INTERVAL '3 days', 'active', 'Maçka Parkı Kahve', 'Kısa yürüyüş ve kahve.', 15, NOW() + INTERVAL '2 days'),
(15, 12, 5, NOW() + INTERVAL '1 month', 'upcoming', 'Antalya Büyük Koşu', 'Hazırlıklar başlasın.', 50, NOW() + INTERVAL '25 days'),

-- Geçmiş ve Tamamlanmış Etkinlikler (Completed)
(1, 9, 2, NOW() - INTERVAL '10 days', 'completed', 'Yıldız Parkı Gezisi', 'Harika bir gündü.', 20, NOW() - INTERVAL '11 days'),
(14, 7, 1, NOW() - INTERVAL '5 days', 'completed', 'Moda Sahili Akşamı', 'Gün batımı.', 25, NOW() - INTERVAL '6 days'),
(7, 6, 2, NOW() - INTERVAL '2 months', 'completed', 'Emirgan Lale Festivali', 'Fotoğraf ağırlıklı.', 40, NOW() - INTERVAL '65 days'),
(5, 11, 1, NOW() - INTERVAL '1 year', 'completed', 'Fenerbahçe Parkı', 'Eski bir anı.', 10, NOW() - INTERVAL '370 days'),

-- İptal Edilenler (Cancelled)
(4, 8, 5, NOW() + INTERVAL '1 day', 'cancelled', 'Aydos Zirve (İptal)', 'Hava muhalefeti.', 10, NOW()), 
(10, 10, 2, NOW() - INTERVAL '1 month', 'cancelled', 'Büyükada Turu', 'Yeterli katılım olmadı.', 30, NOW() - INTERVAL '35 days'),

-- Diğer Aktifler
(2, 1, 1, NOW() + INTERVAL '1 hour', 'active', 'Ani Belgrad Turu', 'Hemen çıkıyoruz.', 5, NOW()),
(1, 9, 9, NOW() + INTERVAL '1 week', 'active', 'Yıldız Fotoğraf Safarisi', 'Makineleri alın.', 15, NOW() + INTERVAL '5 days'),
(3, 3, 1, NOW() + INTERVAL '15 days', 'upcoming', 'Polonezköy 2', 'Tekrar gidiyoruz.', 20, NOW() + INTERVAL '12 days');

-- 12. KATILIMLAR (20+ Kayıt - Composite PK)
INSERT INTO participations (user_id, event_id, is_completed) VALUES
-- Event 1 (Active)
(3, 1, false), (4, 1, false), (5, 1, false), (1, 1, false),
-- Event 7 (Completed - Geçmiş) -> is_completed TRUE olmalı
(2, 7, true), (3, 7, true), (4, 7, true), (11, 7, true),
-- Event 8 (Completed)
(1, 8, true), (5, 8, true), (6, 8, true),
-- Event 2 (Active)
(7, 2, false), (8, 2, false), (1, 2, false),
-- Event 10 (Cancelled)
(2, 10, false), (3, 10, false),
-- Event 4 (Upcoming)
(1, 4, false), (2, 4, false), (15, 4, false), (14, 4, false);

-- 13. YORUMLAR (15 Kayıt)
INSERT INTO route_reviews (route_id, user_id, comment, rating) VALUES
(1, 2, 'Harika bir doğa, kesinlikle tavsiye ederim!', 5),
(1, 3, 'Biraz kalabalıktı ama parkur güzel.', 4),
(2, 5, 'Zemin biraz sert, koşu için ideal değil.', 3),
(4, 1, 'Manzara müthiş ama çok zorlu, su almayı unutmayın.', 5),
(5, 4, 'Köpeğimle çok rahat ettik.', 5),
(2, 8, 'Çok keyifliydi.', 5), 
(3, 1, 'Yollar biraz çamurluydu.', 3),
(6, 12, 'Manzara harika.', 5), 
(10, 6, 'Çok yorucu ama değdi.', 4),
(11, 9, 'Kısa ve öz.', 4),
(12, 15, 'Antalya sıcağında zor ama güzel.', 5),
(1, 7, 'En sevdiğim rota.', 5),
(8, 2, 'Kaybolması kolay, dikkat.', 3),
(9, 1, 'Şehir içinde vaha.', 5),
(7, 14, 'Yoga sonrası yürüyüş için ideal.', 5);

-- 14. KULLANICI ROZETLERİ (Manuel verilenler)
INSERT INTO user_badges (user_id, badge_id) VALUES 
(1, 1), -- Admin Ahmet: İlk Adım
(1, 7), -- Admin Ahmet: Lider Ruh
(7, 5), -- Burak: Maratoncu
(13, 3), -- Ozan: Gümüş Seviye
(2, 1), -- Ayşe: İlk Adım
(3, 1), -- Mehmet: İlk Adım
(15, 7), -- Emre: Lider Ruh
(4, 1), -- Zeynep: İlk Adım
(4, 2), -- Zeynep: Bronz Seviye
(5, 1), -- Can: İlk Adım
(6, 10), -- Elif: Gece Kuşu
(8, 11), -- Selin: Erkenci Kuş
(11, 4), -- Kerem: Altın Seviye
(14, 9), -- Pınar: Fotoğrafçı
(12, 6); -- Deniz: Sosyal Kelebek

-- 15. BİLDİRİMLER (10 Kayıt)
INSERT INTO notifications (user_id, message, is_read, related_link) VALUES
(2, 'Mehmet size arkadaşlık isteği gönderdi.', false, '/friends'),
(4, 'Tebrikler! Gümüş Seviye rozetini kazandınız.', true, '/profile/4'),
(1, 'Kulüp etkinliğiniz onaylandı.', false, '/clubs'),
(3, 'Etkinlik saati değişti.', false, '/events'),
(5, 'Arkadaşlık isteği kabul edildi.', true, '/friends'),
(7, 'Yeni bir rozet kazandınız!', false, '/profile/7'),
(8, 'Rotanıza yorum yapıldı.', true, '/routes'),
(1, 'Kulüp üyelik başvurusu var.', false, '/club/1'),
(9, 'Profilinizi tamamlayın.', true, '/edit_profile'),
(10, 'Haftanın lideri sizsiniz!', false, '/leaderboard');