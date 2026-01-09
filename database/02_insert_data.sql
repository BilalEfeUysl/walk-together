-- 1. HOBİLER (İkonlar Eklendi)
INSERT INTO hobbies (hobby_name, icon) VALUES 
('Doğa Yürüyüşü', 'fas fa-hiking'),
('Kamp', 'fas fa-campground'),
('Fotoğrafçılık', 'fas fa-camera'),
('Bisiklet', 'fas fa-bicycle'),
('Koşu', 'fas fa-running'),
('Yüzme', 'fas fa-swimmer'),
('Yoga', 'fas fa-spa'),
('Tarih', 'fas fa-landmark'),
('Müzik', 'fas fa-music'),
('Resim', 'fas fa-palette')
ON CONFLICT DO NOTHING;

-- 2. KULLANICILAR (ÖNCE BU ÇALIŞMALI)
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

-- 3. KATEGORİLER (İkonlar Düzeltildi)
INSERT INTO categories (category_name, icon_url) VALUES
('Doğa Yürüyüşü', 'fas fa-tree'), 
('Şehir Turu', 'fas fa-city'), 
('Gece Yürüyüşü', 'fas fa-moon'),
('Bisiklet Turu', 'fas fa-bicycle'), 
('Profesyonel Tırmanış', 'fas fa-mountain'), 
('Köpek Gezdirme', 'fas fa-dog'),
('Kanyon Geçişi', 'fas fa-water'), 
('Kuş Gözlemi', 'fas fa-dove'), 
('Fotoğraf Safarisi', 'fas fa-camera'), 
('Yıldız İzleme', 'fas fa-star');

-- 4. KULÜPLER (Kullanıcılar artık var, hata vermez)
INSERT INTO clubs (club_name, description, owner_id) VALUES
('YTÜ Doğa Kulübü', 'Yıldız Teknik öğrencileri için doğa gezileri.', 1),
('İstanbul Maratoncuları', 'Her pazar sabahı koşuyoruz.', 3),
('Gece Kartalları', 'Şehri gece keşfediyoruz.', 7),
('Ankara Yürüyüş', 'Başkent sokakları.', 3),
('İzmir Kordon', 'Sahil yürüyüşleri.', 4),
('Kamp Ateşi', 'Sadece kamp sevenler.', 8),
('Bisiklet Kardeşliği', 'Pedallayanlar buraya.', 11),
('Bursa Dağcıları', 'Uludağ tırmanış ekibi.', 5),
('Karadeniz Fırtınası', 'Yaylaları geziyoruz.', 2),
('Antalya Trekking', 'Likya yolu yolcuları.', 7);

-- 5. KULÜP ÜYELİKLERİ (Composite PK uyumlu)
INSERT INTO club_members (club_id, user_id, role) VALUES
(1, 1, 'admin'), (1, 2, 'member'), (1, 4, 'member'),
(2, 3, 'admin'), (2, 7, 'member'), (3, 7, 'admin'), (3, 5, 'member'),
(2, 1, 'member'), (2, 8, 'member'), (3, 2, 'member'), (3, 10, 'member');

-- 6. ARKADAŞLIKLAR
INSERT INTO friendships (requester_id, addressee_id, status) VALUES
(2, 4, 'accepted'), (3, 7, 'accepted'), (5, 2, 'pending'),
(1, 3, 'pending'), (1, 5, 'accepted'), (4, 8, 'accepted'),
(6, 9, 'rejected'), (7, 10, 'accepted'), (11, 12, 'pending'),
(2, 11, 'accepted');

-- 7. KULLANICI HOBİLERİ (Composite PK uyumlu)
INSERT INTO user_hobbies (user_id, hobby_id) VALUES
(1, (SELECT hobby_id FROM hobbies WHERE hobby_name='Doğa Yürüyüşü')), 
(1, (SELECT hobby_id FROM hobbies WHERE hobby_name='Kamp')), 
(2, (SELECT hobby_id FROM hobbies WHERE hobby_name='Koşu')),
(2, (SELECT hobby_id FROM hobbies WHERE hobby_name='Yoga')),
(3, (SELECT hobby_id FROM hobbies WHERE hobby_name='Koşu'));

-- 8. ROTALAR
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

-- 9. DURAKLAR
INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES
(1, 1, 'Giriş Kapısı', 41.1793, 28.9698), (1, 2, 'Neşet Suyu', 41.1856, 28.9567), (1, 3, 'Üçgen Ev', 41.1920, 28.9480),
(2, 1, 'Dalyan Parkı', 40.9667, 29.0531), (2, 2, 'Şaşkınbakkal', 40.9632, 29.0685), (2, 3, 'Erenköy', 40.9605, 29.0801),
(3, 1, 'Köy Meydanı', 41.1123, 29.2105), (3, 2, 'Yürüyüş Parkuru Başı', 41.1145, 29.2150),
(4, 1, 'Ovacık Başlangıç', 36.5705, 29.1550), (4, 2, 'Kirme Köyü', 36.5450, 29.1320), (4, 3, 'Faralya', 36.5012, 29.1285),
(5, 1, 'Harbiye Girişi', 41.0450, 28.9915), (5, 2, 'Teleferik Altı', 41.0425, 28.9940),
(7, 1, 'İskele', 41.1085, 29.0550), (7, 2, 'Kayalıklar', 41.1100, 29.0570), (7, 3, 'Yoğurtçu Parkı', 40.9850, 29.0300),
(10, 1, 'Saat Kulesi', 40.8755, 29.1275), (10, 2, 'Lunapark Meydanı', 40.8650, 29.1180), (10, 3, 'Aya Yorgi Yokuşu', 40.8600, 29.1150);

-- 10. ETKİNLİKLER
INSERT INTO events (organizer_id, route_id, category_id, event_date, status, title, description, max_participants, deadline) VALUES
(2, 2, 2, '2025-10-15 09:00:00', 'active', 'Hafta sonu sabah koşusu', 'Hafta sonu sabah koşusu.', 15, '2025-10-14 23:59:00'),
(3, 1, 1, '2025-10-16 08:00:00', 'upcoming', 'Belgrad ormanında temiz hava', 'Belgrad ormanında temiz hava.', 50, '2025-10-15 12:00:00'),
(4, 4, 5, '2025-11-01 07:00:00', 'active', 'Profesyoneller için Likya etabı', 'Profesyoneller için Likya etabı.', 10, '2025-10-30 18:00:00'),
(1, 2, 3, '2023-05-20 18:00:00', 'completed', 'Gün batımı yürüyüşü', 'Gün batımı yürüyüşü.', 20, '2023-05-19 18:00:00'),
(5, 7, 2, '2023-06-10 10:00:00', 'completed', 'Moda sahili kahve ve yürüyüş', 'Moda sahili kahve ve yürüyüş.', 30, '2023-06-09 20:00:00'),
(7, 3, 1, '2023-07-01 09:00:00', 'cancelled', 'Hava muhalefeti iptal', 'Hava muhalefeti iptal.', 25, '2023-06-30 15:00:00'),
(2, 5, 6, '2025-10-20 17:00:00', 'upcoming', 'Maçka parkında köpekli yürüyüş', 'Maçka parkında köpekli yürüyüş.', 15, '2025-10-19 12:00:00'),
(8, 8, 5, '2025-10-25 08:30:00', 'active', 'Aydos zirve tırmanışı', 'Aydos zirve tırmanışı.', 12, '2025-10-24 17:00:00'),
(10, 10, 4, '2025-11-05 09:00:00', 'active', 'Büyükada bisiklet ve yürüyüş', 'Büyükada bisiklet ve yürüyüş.', 40, '2025-11-03 23:59:00'),
(1, 1, 1, '2023-09-15 08:00:00', 'completed', 'Sonbahar başlangıcı yürüyüşü', 'Sonbahar başlangıcı yürüyüşü.', 50, '2023-09-14 10:00:00');

-- 11. KATILIMLAR (Composite PK uyumlu)
INSERT INTO participations (user_id, event_id, is_completed) VALUES
(2, 1, false), (3, 1, false), (5, 1, false),
(4, 2, false), (7, 2, false),
(2, 4, true), (3, 4, true), (6, 4, true),
(8, 5, true), (9, 5, false), (11, 8, false), (12, 9, false);

-- 12. ROZETLER (Route tipi kaldırıldı, ikonlar güncellendi)
INSERT INTO badges (badge_name, description, badge_type, required_value, icon_url) VALUES
('Yeni Başlayan', 'İlk etkinliğine katıldı.', 'User', 1, 'fas fa-hiking'),
('Bronz Adımlar', 'Toplam 500 puana ulaştı.', 'User', 500, 'fas fa-shoe-prints'),
('Gümüş Rota', 'Toplam 1000 puana ulaştı.', 'User', 1000, 'fas fa-map'),
('Maraton Ustası', 'Toplam 2000 puana ulaştı.', 'User', 2000, 'fas fa-running'),
('Sosyal Kelebek', '10 arkadaşa ulaştı.', 'User', 10, 'fas fa-users'),
('Gece Kuşu', 'Gece etkinliğine katıldı.', 'User', 0, 'fas fa-moon'),
('Lider Ruh', 'Bir kulüp kurdu.', 'User', 0, 'fas fa-crown');

-- 13. KULLANICI ROZETLERİ (Route rozetleri silindi, Composite PK uyumlu)
INSERT INTO user_badges (user_id, badge_id) VALUES 
(1, (SELECT badge_id FROM badges WHERE badge_name='Yeni Başlayan')), 
(7, (SELECT badge_id FROM badges WHERE badge_name='Maraton Ustası'));

-- 14. BİLDİRİMLER
INSERT INTO notifications (user_id, message, is_read) VALUES
(2, 'Mehmet size arkadaşlık isteği gönderdi.', false),
(4, 'Tebrikler! Gümüş Rota rozetini kazandınız.', true),
(1, 'Kulüp etkinliğiniz onaylandı.', false),
(3, 'Etkinlik saati değişti.', false), (5, 'Arkadaşlık isteği kabul edildi.', true),
(7, 'Yeni bir rozet kazandınız!', false), (8, 'Rotanıza yorum yapıldı.', true),
(1, 'Kulüp üyelik başvurusu var.', false), (9, 'Profilinizi tamamlayın.', true),
(10, 'Haftanın lideri sizsiniz!', false);

-- 15. DUYURULAR
INSERT INTO club_announcements (club_id, sender_id, message) VALUES
(1, 1, 'Hafta sonu etkinlik iptal.'), (1, 1, 'Yeni rota eklendi.'),
(2, 3, 'Pazar sabahı 06:00 toplanma.'), (2, 3, 'Forma siparişleri geldi.'),
(3, 7, 'Gece yürüyüşü için fener almayı unutmayın.'),
(1, 2, 'Aidatlar hakkında bilgilendirme.'), (3, 5, 'Fotoğrafları gruba attım.'),
(2, 7, 'Katılım listesi doldu.'), (1, 4, 'Hava durumu yağmurlu görünüyor.'),
(3, 7, 'Bir sonraki rota önerilerinizi bekliyorum.');

-- 16. YORUMLAR
INSERT INTO route_reviews (route_id, user_id, comment, rating) VALUES
(1, 2, 'Harika bir doğa, kesinlikle tavsiye ederim!', 5),
(1, 3, 'Biraz kalabalıktı ama parkur güzel.', 4),
(2, 5, 'Zemin biraz sert, koşu için ideal değil.', 3),
(4, 1, 'Manzara müthiş ama çok zorlu, su almayı unutmayın.', 5),
(5, 4, 'Köpeğimle çok rahat ettik.', 5),
(2, 8, 'Çok keyifliydi.', 5), (3, 1, 'Yollar biraz çamurluydu.', 3),
(7, 12, 'Manzara harika.', 5), (10, 6, 'Çok yorucu ama değdi.', 4),
(11, 9, 'Kısa ve öz.', 4);

-- 17. VARSAYILAN RÜTBELER
INSERT INTO ranks (name, min_points, color_class) VALUES 
('Yeni Başlayan', 0, 'bg-slate-100 text-slate-600 border-slate-200'),
('Tecrübeli', 100, 'bg-yellow-100 text-yellow-700 border-yellow-200'),
('Gezgin', 300, 'bg-green-100 text-green-700 border-green-200'),
('Usta Kâşif', 1000, 'bg-blue-100 text-blue-700 border-blue-200'),
('Efsane', 2000, 'bg-purple-100 text-purple-700 border-purple-200');


-- Mevcut ID sayacını öğrenip çakışmayı önleyelim (Garanti olsun diye yüksek ID veriyoruz)
-- 1. GELECEKTEKİ AKTİF ETKİNLİK (Upcoming)
INSERT INTO events (organizer_id, route_id, category_id, title, description, event_date, status, max_participants) 
VALUES (2, 1, 1, 'Belgrad Sabah Koşusu', 'Sabah 6''da buluşup temiz havada koşuyoruz.', NOW() + INTERVAL '5 days', 'active', 10);

-- 2. GELECEKTEKİ İPTAL EDİLMİŞ ETKİNLİK (Cancelled - Listede görünmeli ama iptal etiketiyle)
INSERT INTO events (organizer_id, route_id, category_id, title, description, event_date, status, max_participants) 
VALUES (3, 2, 2, 'Adalar Turu (İptal)', 'Hava muhalefeti nedeniyle iptal edildi.', NOW() + INTERVAL '2 days', 'cancelled', 20);

-- 3. GEÇMİŞ VE TAMAMLANMIŞ ETKİNLİK (Completed - Sadece filtreyle görünmeli)
INSERT INTO events (organizer_id, route_id, category_id, title, description, event_date, status, max_participants) 
VALUES (1, 3, 3, 'Geçen Ayki Kamp', 'Çok güzel bir kamptı.', NOW() - INTERVAL '1 month', 'completed', 5);

-- 4. GEÇMİŞ AMA İPTAL OLMUŞ (Completed/Cancelled - Geçmişte görünmeli)
INSERT INTO events (organizer_id, route_id, category_id, title, description, event_date, status, max_participants) 
VALUES (4, 4, 1, 'Eski İptal Olan Yürüyüş', 'Yeterli katılım olmadı.', NOW() - INTERVAL '2 months', 'cancelled', 10);