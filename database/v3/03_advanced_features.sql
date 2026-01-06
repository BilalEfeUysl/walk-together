-- ==========================================
-- 1. INDEXLER (B-TREE & PATTERN OPS)
-- ==========================================
-- Arama performansı için (ILIKE sorgularını hızlandırır)
CREATE INDEX IF NOT EXISTS idx_event_desc_btree ON events USING btree (description text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_route_name_btree ON routes USING btree (route_name text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_club_name_btree ON clubs USING btree (club_name text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_user_username_btree ON users USING btree (username text_pattern_ops);

-- [YENİ] Arayüzde ILIKE araması yapıldığı için LOWER fonksiyonlu index
CREATE INDEX IF NOT EXISTS idx_user_username_lower ON users (LOWER(username));

-- Standart indexler
CREATE INDEX IF NOT EXISTS idx_stop_location ON stops(location_name);
CREATE INDEX IF NOT EXISTS idx_event_date ON events(event_date);

-- ==========================================
-- 2. VIEWS (RAPORLAMA)
-- ==========================================

-- VIEW: POPÜLER ROTALAR
CREATE OR REPLACE VIEW view_popular_routes AS
SELECT 
    r.route_name,       -- [0] Rota Adı
    r.difficulty_level, -- [1] Zorluk
    r.distance_km,      -- [2] Mesafe
    u.username AS creator_name, -- [3] Oluşturan
    COUNT(DISTINCT e.event_id) AS event_count, -- [4] Etkinlik Sayısı
    ROUND(AVG(COALESCE(rr.rating, 0)), 1) AS average_rating, -- [5] Puan
    COUNT(DISTINCT rr.review_id) AS review_count, -- [6] Yorum Sayısı
    r.route_id          -- [7] ID
FROM routes r
JOIN users u ON r.creator_id = u.user_id
LEFT JOIN events e ON r.route_id = e.route_id
LEFT JOIN route_reviews rr ON r.route_id = rr.route_id
GROUP BY r.route_id, r.route_name, r.difficulty_level, r.distance_km, u.username
ORDER BY event_count DESC, average_rating DESC;

-- VIEW: LİDERLİK TABLOSU
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

-- [YENİ] VIEW: POPÜLER KULÜPLER (AGGREGATE + HAVING)
DROP VIEW IF EXISTS view_popular_clubs CASCADE;
CREATE OR REPLACE VIEW view_popular_clubs AS
SELECT 
    c.club_id,
    c.club_name,
    c.description,      -- Arayüz için gerekli
    c.club_image_url,   -- Arayüz için gerekli
    u.username,         -- Arayüzde başkan adı için gerekli
    COUNT(cm.user_id) as member_count
FROM clubs c
JOIN users u ON c.owner_id = u.user_id
JOIN club_members cm ON c.club_id = cm.club_id
GROUP BY c.club_id, c.club_name, c.description, c.club_image_url, u.username
HAVING COUNT(cm.user_id) >= 2
ORDER BY member_count DESC;

-- 2. [YENİ] Yalnız Kullanıcılar View'ı (EXCEPT Kullanımı)
-- Mantık: (Tüm Kullanıcılar) EXCEPT (Arkadaşlığı Olanlar)
DROP VIEW IF EXISTS view_potential_friends_base;

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
-- ==========================================

-- [YENİ] FONKSİYON: CURSOR KULLANIMI
-- 1. Eski gereksiz fonksiyonu silelim
DROP FUNCTION IF EXISTS get_event_participants_cursor(INTEGER);

-- 2. Yeni CURSOR fonksiyonunu oluşturalım
-- YENİ FONKSİYON: Cursor ile gezip Tablo döner
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
    -- Cursor Tanımı: Verileri hafızaya alır
    stop_cursor CURSOR FOR 
        SELECT s.stop_id, s.route_id, s.stop_order, s.location_name, s.latitude, s.longitude
        FROM stops s
        WHERE s.route_id = p_route_id
        ORDER BY s.stop_order ASC;
        
    rec RECORD;
BEGIN
    OPEN stop_cursor;
    
    LOOP
        FETCH stop_cursor INTO rec;
        EXIT WHEN NOT FOUND;
        
        -- Cursor'dan okunan satırı sonuç tablosuna ekle
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

-- [YENİ] FONKSİYON: TABLE RETURN
DROP FUNCTION IF EXISTS search_routes_by_distance(DECIMAL, DECIMAL);

CREATE OR REPLACE FUNCTION search_routes_by_distance(min_km DECIMAL, max_km DECIMAL)
RETURNS TABLE (
    r_id INTEGER,       -- [YENİ] ID Dönüşü
    r_name VARCHAR, 
    r_dist DECIMAL, 
    r_diff VARCHAR,
    creator_name VARCHAR -- [YENİ] Kartta göstermek için
) AS $$
BEGIN
    RETURN QUERY 
    SELECT r.route_id, r.route_name, r.distance_km, r.difficulty_level, u.username
    FROM routes r
    JOIN users u ON r.creator_id = u.user_id
    WHERE r.distance_km BETWEEN min_km AND max_km;
END;
$$ LANGUAGE plpgsql;

-- [YENİ] FONKSİYON: SCALAR (SEVİYE HESAPLAMA)
CREATE OR REPLACE FUNCTION calculate_user_level(points INTEGER)
RETURNS VARCHAR AS $$
BEGIN
    IF points < 500 THEN RETURN 'Başlangıç';
    ELSIF points < 1500 THEN RETURN 'Orta Seviye';
    ELSE RETURN 'Usta Yürüyüşçü';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- 4. TRIGGERLAR
-- ==========================================

-- TRIGGER: ROZET KAZANMA + BİLDİRİM
CREATE OR REPLACE FUNCTION check_and_award_badges()
RETURNS TRIGGER AS $$
DECLARE
    target_badge RECORD;
BEGIN
    FOR target_badge IN SELECT * FROM badges WHERE badge_type = 'User' LOOP
        IF NEW.total_points >= target_badge.required_value THEN
            IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = NEW.user_id AND badge_id = target_badge.badge_id) THEN
                
                INSERT INTO user_badges (user_id, badge_id) VALUES (NEW.user_id, target_badge.badge_id);
                
                INSERT INTO notifications (user_id, message) 
                VALUES (NEW.user_id, 'Tebrikler! Yeni bir rozet kazandınız: ' || target_badge.badge_name);
                
            END IF;
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_award_user_badge ON users;
CREATE TRIGGER trg_award_user_badge
AFTER UPDATE OF total_points ON users
FOR EACH ROW
EXECUTE FUNCTION check_and_award_badges();

-- TRIGGER: PUAN HESAPLAMA
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
        
        UPDATE users SET total_points = total_points + points_to_add
        WHERE user_id = NEW.user_id;

        -- [YENİ] Bildirim gönder
        INSERT INTO notifications (user_id, message) 
        VALUES (NEW.user_id, 'Tebrikler! Etkinlik tamamlandı ve ' || points_to_add || ' puan kazandın! 🏆');
        
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_add_points ON participations;
CREATE TRIGGER trg_add_points
AFTER UPDATE ON participations
FOR EACH ROW
EXECUTE FUNCTION update_points_on_completion();


-- KULLANICI SİLİNDİĞİNDE İÇERİKLERİN BOŞA DÜŞEBİLMESİ İÇİN AYARLAR

-- 1. Rotalar tablosundaki "creator_id" zorunluluğunu kaldır
ALTER TABLE routes ALTER COLUMN creator_id DROP NOT NULL;

-- 2. Etkinlikler tablosundaki "organizer_id" zorunluluğunu kaldır
ALTER TABLE events ALTER COLUMN organizer_id DROP NOT NULL;

-- 3. (Opsiyonel) Eğer Foreign Key kısıtlamaları "ON DELETE CASCADE" ise bunları değiştir
-- Normalde varsayılan "NO ACTION"dır ama garanti olsun diye kısıtlamayı güncelliyoruz.
ALTER TABLE routes DROP CONSTRAINT IF EXISTS routes_creator_id_fkey;
ALTER TABLE routes ADD CONSTRAINT routes_creator_id_fkey 
    FOREIGN KEY (creator_id) REFERENCES users(user_id) ON DELETE SET NULL;

ALTER TABLE events DROP CONSTRAINT IF EXISTS events_organizer_id_fkey;
ALTER TABLE events ADD CONSTRAINT events_organizer_id_fkey 
    FOREIGN KEY (organizer_id) REFERENCES users(user_id) ON DELETE SET NULL;