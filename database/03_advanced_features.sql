-- ==========================================
-- 1. INDEXLER (PERFORMANS İYİLEŞTİRMELERİ)
-- [GEREKSİNİM]: Tasarladığınız veritabanında index oluşturulmalıdır.
-- ==========================================

-- [INDEX 1] Tarih Sorgu Performansı
-- Arayüzdeki "Yaklaşan Etkinlikler" (WHERE event_date > NOW) sorgusunu hızlandırır.
CREATE INDEX idx_event_date ON events(event_date);

-- [INDEX 2] Arama Performansı
-- Arayüzdeki "Kullanıcı Arama" (ILIKE) işleminin performansını artırır.
CREATE INDEX idx_user_username_lower ON users (LOWER(username));

-- ==========================================
-- 2. VIEWS (RAPORLAMA VE SANAL TABLOLAR)
-- ==========================================

-- [VIEW 1] DETAYLI RAPORLAMA VIEW'I
-- Rotaları, etkinlik sayılarını ve ortalama puanları (Aggregate) tek tabloda sunar.
CREATE OR REPLACE VIEW view_popular_routes AS
SELECT 
    r.route_name,       
    r.difficulty_level, 
    r.distance_km,      
    u.username AS creator_name, 
    COUNT(DISTINCT e.event_id) AS event_count,    -- [Aggregate] Etkinlik Sayısı
    ROUND(AVG(COALESCE(rr.rating, 0)), 1) AS average_rating, -- [Aggregate] Ort. Puan
    COUNT(DISTINCT rr.review_id) AS review_count, 
    r.route_id          
FROM routes r
JOIN users u ON r.creator_id = u.user_id
LEFT JOIN events e ON r.route_id = e.route_id
LEFT JOIN route_reviews rr ON r.route_id = rr.route_id
GROUP BY r.route_id, r.route_name, r.difficulty_level, r.distance_km, u.username
ORDER BY event_count DESC, average_rating DESC;

-- [VIEW 2] WINDOW FUNCTION KULLANIMI
-- Liderlik tablosunda sıralama yapmak için RANK() fonksiyonu kullanılmıştır.
CREATE OR REPLACE VIEW view_leaderboard AS
SELECT 
    RANK() OVER (ORDER BY total_points DESC) as siralama,
    username,
    role,
    total_points,
    user_id,
    profile_picture_url
FROM users
WHERE role != 'admin';

-- [VIEW 3] AGGREGATE VE HAVING KULLANIMI
-- [GEREKSİNİM]: "Sorgularınızın en az biri having ifadesi içermelidir." şartını sağlar.
CREATE OR REPLACE VIEW view_popular_clubs AS
SELECT 
    c.club_id,
    c.club_name,
    c.description,      
    c.club_image_url,   
    u.username,         
    COUNT(cm.user_id) as member_count -- [Aggregate]
FROM clubs c
JOIN users u ON c.owner_id = u.user_id
JOIN club_members cm ON c.club_id = cm.club_id
GROUP BY c.club_id, c.club_name, c.description, c.club_image_url, u.username
HAVING COUNT(cm.user_id) >= 2 -- [HAVING] En az 2 üyesi olan kulüpleri filtreler.
ORDER BY member_count DESC;

-- [VIEW 4] KÜME OPERATÖRLERİ (EXCEPT)
-- [GEREKSİNİM]: "Sorgulardan en az birinde except kullanmış olmalısınız." şartını sağlar.
-- Tüm kullanıcılardan, zaten arkadaş olunanları (accepted) çıkarır.
CREATE OR REPLACE VIEW view_potential_friends_base AS
SELECT user_id FROM users
EXCEPT
(
    SELECT requester_id FROM friendships WHERE status = 'accepted'
    UNION
    SELECT addressee_id FROM friendships WHERE status = 'accepted'
);

-- ==========================================
-- 3. FONKSİYONLAR (STORED PROCEDURES)
-- [GEREKSİNİM]: Arayüzden parametre alan 3 farklı fonksiyon.
-- [GEREKSİNİM]: En az birinde "record" ve "cursor" kullanımı.
-- ==========================================

-- [FONKSİYON 1] CURSOR VE RECORD KULLANIMI
-- [GEREKSİNİM]: "Record ve Cursor tanımı-kullanımı olmalıdır." şartını sağlar.
CREATE OR REPLACE FUNCTION get_stops_via_cursor(p_route_id INTEGER)
RETURNS TABLE (
    stop_id INTEGER,
    route_id INTEGER,
    stop_order INTEGER,
    location_name VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL
) AS $$
DECLARE
    -- [CURSOR TANIMI]
    stop_cursor CURSOR FOR 
        SELECT s.stop_id, s.route_id, s.stop_order, s.location_name, s.latitude, s.longitude
        FROM stops s
        WHERE s.route_id = p_route_id
        ORDER BY s.stop_order ASC;
    rec RECORD; -- [RECORD TANIMI]
BEGIN
    OPEN stop_cursor;
    LOOP
        FETCH stop_cursor INTO rec; -- Cursor ile satır satır okuma
        EXIT WHEN NOT FOUND;
        stop_id := rec.stop_id;
        route_id := rec.route_id;
        stop_order := rec.stop_order;
        location_name := rec.location_name;
        latitude := rec.latitude;
        longitude := rec.longitude;
        RETURN NEXT; 
    END LOOP;
    CLOSE stop_cursor;
END;
$$ LANGUAGE plpgsql;

-- [FONKSİYON 2] PARAMETRELİ TABLO DÖNDÜREN FONKSİYON
-- [GEREKSİNİM]: "Arayüzden girilen değerleri parametre olarak alıp..." şartını sağlar.
-- Kullanıcı arayüzünden gelen min_km ve max_km değerlerine göre filtreleme yapar.
CREATE OR REPLACE FUNCTION search_routes_by_distance(min_km DECIMAL, max_km DECIMAL)
RETURNS TABLE (
    r_id INTEGER,       
    r_name VARCHAR, 
    r_dist DECIMAL, 
    r_diff VARCHAR,
    creator_name VARCHAR 
) AS $$
BEGIN
    RETURN QUERY 
    SELECT r.route_id, r.route_name, r.distance_km, r.difficulty_level, u.username
    FROM routes r
    JOIN users u ON r.creator_id = u.user_id
    WHERE r.distance_km BETWEEN min_km AND max_km;
END;
$$ LANGUAGE plpgsql;

-- [FONKSİYON 3] SCALAR FONKSİYON (TEK DEĞER DÖNEN)
-- Kullanıcının puanına göre seviyesini (Rütbe Adı) hesaplar.
CREATE OR REPLACE FUNCTION calculate_user_level(points INTEGER)
RETURNS VARCHAR AS $$
DECLARE
    rank_name VARCHAR;
BEGIN
    SELECT name INTO rank_name
    FROM ranks
    WHERE min_points <= points
    ORDER BY min_points DESC
    LIMIT 1;
    
    IF rank_name IS NULL THEN
        RETURN 'Tanımsız';
    ELSE
        RETURN rank_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- 4. TRIGGERLAR (TETİKLEYİCİLER)
-- [GEREKSİNİM]: 2 adet trigger tanımlamalı ve arayüzden tetiklemelisiniz.
-- [GEREKSİNİM]: Trigger’ın çalıştığına dair arayüze bilgilendirme mesajı döndürülmelidir.
-- ==========================================

-- [TRIGGER 1] ROZET SİSTEMİ VE BİLDİRİM
-- Kullanıcı puanı güncellendiğinde (AFTER UPDATE) çalışır.
-- Şart sağlanırsa Notifications tablosuna kayıt atarak arayüze mesaj gönderir.
CREATE OR REPLACE FUNCTION check_and_award_badges()
RETURNS TRIGGER AS $$
DECLARE
    target_badge RECORD;
BEGIN
    FOR target_badge IN SELECT * FROM badges WHERE badge_type = 'User' LOOP
        IF NEW.total_points >= target_badge.required_value THEN
            -- Composite Key kontrolü (Daha önce almış mı?)
            IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = NEW.user_id AND badge_id = target_badge.badge_id) THEN
                
                INSERT INTO user_badges (user_id, badge_id) VALUES (NEW.user_id, target_badge.badge_id);
                
                -- [BİLDİRİM] Arayüzde görünecek mesaj burada oluşturulur.
                INSERT INTO notifications (user_id, message, related_link) 
                VALUES (NEW.user_id, 'Tebrikler! Yeni bir rozet kazandınız: ' || target_badge.badge_name, '/profile/' || NEW.user_id);
                
            END IF;
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_award_user_badge
AFTER UPDATE OF total_points ON users
FOR EACH ROW
EXECUTE FUNCTION check_and_award_badges();

-- [TRIGGER 2] ETKİNLİK TAMAMLAMA VE PUAN HESAPLAMA
-- Katılım durumu (is_completed) değiştiğinde çalışır.
-- Rotanın mesafesine göre puan hesaplar ve kullanıcıya ekler.
CREATE OR REPLACE FUNCTION update_points_on_completion()
RETURNS TRIGGER AS $$
DECLARE
    route_km DECIMAL;
    points_to_add INTEGER;
BEGIN
    IF NEW.is_completed = true AND OLD.is_completed = false THEN
        SELECT r.distance_km INTO route_km
        FROM events e
        JOIN routes r ON e.route_id = r.route_id
        WHERE e.event_id = NEW.event_id;
        
        points_to_add := CAST(route_km * 10 AS INTEGER);
        
        -- Zincirleme Reaksiyon: Bu update işlemi yukarıdaki Rozet Trigger'ını tetikler.
        UPDATE users SET total_points = total_points + points_to_add
        WHERE user_id = NEW.user_id;

        -- [BİLDİRİM] Kullanıcıya puan kazandığına dair mesaj gönderilir.
        INSERT INTO notifications (user_id, message, related_link) 
        VALUES (NEW.user_id, 'Tebrikler! Etkinlik tamamlandı ve ' || points_to_add || ' puan kazandın! 🏆', '/leaderboard');
        
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_add_points
AFTER UPDATE ON participations
FOR EACH ROW
EXECUTE FUNCTION update_points_on_completion();