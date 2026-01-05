-- 1. KULLANICILAR
INSERT INTO users (username, password, role, total_points, profile_picture_url, bio, gender, birth_date, city) VALUES
('admin_ahmet', 'admin123', 'admin', 1500, 'https://ui-avatars.com/api/?name=Admin+Ahmet&background=random', 'Yönetici.', 'Male', '1990-05-15', 'İstanbul'),
('ayse_yurur', 'sifre1', 'user', 500, 'https://ui-avatars.com/api/?name=Ayse+Yurur&background=random', 'Doğa aşığı.', 'Female', '1998-03-22', 'İstanbul'),
('mehmet_kosar', 'sifre2', 'user', 850, NULL, 'Koşucu.', 'Male', '1995-11-10', 'Ankara'),
('zeynep_dagci', 'sifre3', 'user', 1200, 'https://ui-avatars.com/api/?name=Zeynep+Dagci&background=random', 'Zirveci.', 'Female', '2000-01-30', 'İzmir'),
('can_trekking', 'sifre4', 'user', 300, NULL, 'Acemi.', 'Male', '2003-07-14', 'Bursa'),
('elif_dogasever', 'sifre5', 'user', 0, 'https://ui-avatars.com/api/?name=Elif+Dogasever&background=random', 'Huzur.', 'Female', '1999-09-09', 'İstanbul'),
('burak_hizli', 'sifre6', 'user', 2100, NULL, 'Hız.', 'Male', '1992-12-05', 'Antalya'),
('selin_kamp', 'sifre7', 'user', 650, 'https://ui-avatars.com/api/?name=Selin+Kamp&background=random', 'Kampçı.', 'Female', '2001-06-18', 'Muğla'),
('mert_yolcu', 'sifre8', 'user', 100, NULL, NULL, 'Unspecified', '1997-02-14', 'İstanbul'),
('damla_gezgin', 'sifre9', 'user', 450, 'https://ui-avatars.com/api/?name=Damla+Gezgin&background=random', 'Gezgin.', 'Female', '1996-08-30', 'İzmir'),
('kerem_bisiklet', 'sifre10', 'user', 900, NULL, 'Bisikletçi.', 'Male', '1994-04-25', 'İstanbul'),
('deniz_mavi', 'sifre11', 'user', 50, NULL, NULL, 'Unspecified', '2002-10-10', 'Ankara');

-- 2. KATEGORİLER
INSERT INTO categories (category_name, icon_url) VALUES
('Doğa Yürüyüşü', 'tree.png'), ('Şehir Turu', 'city.png'), ('Gece Yürüyüşü', 'moon.png'),
('Bisiklet Turu', 'bike.png'), ('Profesyonel Tırmanış', 'mountain.png'), ('Köpek Gezdirme', 'dog.png');

-- 3. KULÜPLER VE ÜYELİKLER
INSERT INTO clubs (club_name, description, owner_id) VALUES
('YTÜ Doğa Kulübü', 'Yıldız Teknik öğrencileri için doğa gezileri.', 1),
('İstanbul Maratoncuları', 'Her pazar sabahı koşuyoruz.', 3),
('Gece Kartalları', 'Şehri gece keşfediyoruz.', 7);

INSERT INTO club_members (club_id, user_id, role) VALUES
(1, 1, 'admin'), (1, 2, 'member'), (1, 4, 'member'),
(2, 3, 'admin'), (2, 7, 'member'), (3, 7, 'admin'), (3, 5, 'member');

-- 4. ARKADAŞLIKLAR
INSERT INTO friendships (requester_id, addressee_id, status) VALUES
(2, 4, 'accepted'), (3, 7, 'accepted'), (5, 2, 'pending');

-- 5. BİLDİRİMLER
INSERT INTO notifications (user_id, message, is_read) VALUES
(2, 'Mehmet size arkadaşlık isteği gönderdi.', false),
(4, 'Tebrikler! Gümüş Rota rozetini kazandınız.', true),
(1, 'Kulüp etkinliğiniz onaylandı.', false);

-- 6. KULLANICI HOBİLERİ
-- Not: Hobi isimlerini ID'ye çevirerek ekliyoruz
INSERT INTO user_hobbies (user_id, hobby_id) VALUES
(1, (SELECT hobby_id FROM hobbies WHERE hobby_name='Doğa Yürüyüşü')), 
(1, (SELECT hobby_id FROM hobbies WHERE hobby_name='Kamp')), 
(2, (SELECT hobby_id FROM hobbies WHERE hobby_name='Koşu')),
(2, (SELECT hobby_id FROM hobbies WHERE hobby_name='Yoga')),
(3, (SELECT hobby_id FROM hobbies WHERE hobby_name='Koşu'));

-- 7. ROTALAR
INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) VALUES
(1, 'Belgrad Ormanı Büyük Tur', 6.5, 'Medium', 90),
(1, 'Caddebostan Sahil Yolu', 5.0, 'Easy', 60),
(3, 'Polonezköy Tabiat Parkı', 4.2, 'Medium', 75),
(4, 'Likya Yolu Başlangıç', 12.0, 'Hard', 240),
(2, 'Maçka Parkı Turu', 2.0, 'Easy', 30),
(7, 'Emirgan Korusu Yokuşu', 3.5, 'Hard', 50),
(5, 'Moda Sahili Yürüyüşü', 4.0, 'Easy', 45),
(3, 'Aydos Ormanı Zirve', 8.0, 'Hard', 150),
(8, 'Yıldız Parkı Gezisi', 2.5, 'Medium', 40),
(10, 'Büyükada Turu', 14.0, 'Hard', 300),
(2, 'Fenerbahçe Parkı', 1.5, 'Easy', 25);

-- 8. YORUMLAR
INSERT INTO route_reviews (route_id, user_id, comment, rating) VALUES
(1, 2, 'Harika bir doğa, kesinlikle tavsiye ederim!', 5),
(1, 3, 'Biraz kalabalıktı ama parkur güzel.', 4),
(2, 5, 'Zemin biraz sert, koşu için ideal değil.', 3),
(4, 1, 'Manzara müthiş ama çok zorlu, su almayı unutmayın.', 5),
(5, 4, 'Köpeğimle çok rahat ettik.', 5);

-- 9. DURAKLAR (Örnek koordinatlar)
INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(1, 1, 'Giriş Kapısı', 41.1793, 28.9698), (1, 2, 'Neşet Suyu', 41.1856, 28.9567), (1, 3, 'Üçgen Ev', 41.1920, 28.9480),
(2, 1, 'Dalyan Parkı', 40.9667, 29.0531), (2, 2, 'Şaşkınbakkal', 40.9632, 29.0685), (2, 3, 'Erenköy', 40.9605, 29.0801),
(3, 1, 'Köy Meydanı', 41.1123, 29.2105), (3, 2, 'Yürüyüş Parkuru Başı', 41.1145, 29.2150),
(4, 1, 'Ovacık Başlangıç', 36.5705, 29.1550), (4, 2, 'Kirme Köyü', 36.5450, 29.1320), (4, 3, 'Faralya', 36.5012, 29.1285),
(5, 1, 'Harbiye Girişi', 41.0450, 28.9915), (5, 2, 'Teleferik Altı', 41.0425, 28.9940),
(7, 1, 'İskele', 41.1085, 29.0550), (7, 2, 'Kayalıklar', 41.1100, 29.0570), (7, 3, 'Yoğurtçu Parkı', 40.9850, 29.0300),
(10, 1, 'Saat Kulesi', 40.8755, 29.1275), (10, 2, 'Lunapark Meydanı', 40.8650, 29.1180), (10, 3, 'Aya Yorgi Yokuşu', 40.8600, 29.1150);

-- 10. ETKİNLİKLER
INSERT INTO events (organizer_id, route_id, category_id, event_date, status, description, max_participants, deadline) VALUES
(2, 2, 2, '2025-10-15 09:00:00', 'active', 'Hafta sonu sabah koşusu.', 15, '2025-10-14 23:59:00'),
(3, 1, 1, '2025-10-16 08:00:00', 'upcoming', 'Belgrad ormanında temiz hava.', 50, '2025-10-15 12:00:00'),
(4, 4, 5, '2025-11-01 07:00:00', 'active', 'Profesyoneller için Likya etabı.', 10, '2025-10-30 18:00:00'),
(1, 2, 3, '2023-05-20 18:00:00', 'completed', 'Gün batımı yürüyüşü.', 20, '2023-05-19 18:00:00'),
(5, 7, 2, '2023-06-10 10:00:00', 'completed', 'Moda sahili kahve ve yürüyüş.', 30, '2023-06-09 20:00:00'),
(7, 3, 1, '2023-07-01 09:00:00', 'cancelled', 'Hava muhalefeti iptal.', 25, '2023-06-30 15:00:00'),
(2, 5, 6, '2025-10-20 17:00:00', 'upcoming', 'Maçka parkında köpekli yürüyüş.', 15, '2025-10-19 12:00:00'),
(8, 8, 5, '2025-10-25 08:30:00', 'active', 'Aydos zirve tırmanışı.', 12, '2025-10-24 17:00:00'),
(10, 10, 4, '2025-11-05 09:00:00', 'active', 'Büyükada bisiklet ve yürüyüş.', 40, '2025-11-03 23:59:00'),
(1, 1, 1, '2023-09-15 08:00:00', 'completed', 'Sonbahar başlangıcı yürüyüşü.', 50, '2023-09-14 10:00:00');

-- 11. KATILIMLAR
INSERT INTO participations (user_id, event_id, is_completed) VALUES
(2, 1, false), (3, 1, false), (5, 1, false),
(4, 2, false), (7, 2, false),
(2, 4, true), (3, 4, true), (6, 4, true),
(8, 5, true), (9, 5, false), (11, 8, false), (12, 9, false);

-- 12. ROZETLER
INSERT INTO badges (badge_name, description, badge_type, required_value) VALUES
('Yeni Başlayan', 'İlk etkinliğine katıldı.', 'User', 1),
('Bronz Adımlar', 'Toplam 500 puana ulaştı.', 'User', 500),
('Gümüş Rota', 'Toplam 1000 puana ulaştı.', 'User', 1000),
('Maraton Ustası', 'Toplam 2000 puana ulaştı.', 'User', 2000),
('Popüler Rota', 'Bu rotada 5''ten fazla etkinlik düzenlendi.', 'Route', 5),
('Zorlu Parkur', 'Bu rota "Hard" seviyesindedir.', 'Route', 0),
('Manzara Ödülü', 'Kullanıcılar tarafından çok beğenildi.', 'Route', 0);

INSERT INTO user_badges (user_id, badge_id) VALUES (1, 1), (7, 4);
INSERT INTO route_badges (route_id, badge_id) VALUES (1, 5), (4, 6);