-- ==========================================
-- 1. VIEW: POPÜLER ROTALAR (GÜNCELLENDİ: PUANLAMA EKLENDİ)
-- ==========================================
CREATE OR REPLACE VIEW view_popular_routes AS
SELECT 
    r.route_name,
    r.difficulty_level,
    r.distance_km,
    u.username AS creator_name,
    COUNT(DISTINCT e.event_id) AS event_count,
    ROUND(AVG(rr.rating), 1) AS average_rating, -- YENİ: Ortalama Puan (Örn: 4.5)
    COUNT(DISTINCT rr.review_id) AS review_count
FROM routes r
JOIN users u ON r.creator_id = u.user_id
LEFT JOIN events e ON r.route_id = e.route_id
LEFT JOIN route_reviews rr ON r.route_id = rr.route_id -- Yorumları bağladık
GROUP BY r.route_id, r.route_name, r.difficulty_level, r.distance_km, u.username
ORDER BY event_count DESC, average_rating DESC;

-- ==========================================
-- 2. VIEW: LİDERLİK TABLOSU
-- ==========================================
CREATE OR REPLACE VIEW view_leaderboard AS
SELECT 
    RANK() OVER (ORDER BY total_points DESC) as siralama,
    username,
    role,
    total_points,
    user_id -- <--- YENİ EKLENEN KISIM (Link verebilmek için lazım)
FROM users
WHERE role != 'admin';

-- ==========================================
-- 3. PERFORMANS İÇİN INDEXLER
-- ==========================================
CREATE INDEX idx_user_search ON users(username);
CREATE INDEX idx_route_search ON routes(route_name);
CREATE INDEX idx_stop_search ON stops(location_name);
CREATE INDEX idx_club_search ON clubs(club_name);
CREATE INDEX idx_event_date ON events(event_date);

-- ==========================================
-- 4. KARMAŞIK SORGULAR
-- ==========================================
-- Kulüp Başkanları
SELECT c.club_name, u.username as president
FROM clubs c
JOIN users u ON c.owner_id = u.user_id;

-- ==========================================
-- 5. TRIGGER: ROZET KAZANMA + BİLDİRİM (GÜNCELLENDİ) 🔔
-- ==========================================
CREATE OR REPLACE FUNCTION check_and_award_badges()
RETURNS TRIGGER AS $$
DECLARE
    target_badge RECORD;
BEGIN
    FOR target_badge IN SELECT * FROM badges WHERE badge_type = 'User' LOOP
        IF NEW.total_points >= target_badge.required_value THEN
            IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = NEW.user_id AND badge_id = target_badge.badge_id) THEN
                
                -- 1. Rozeti Ver
                INSERT INTO user_badges (user_id, badge_id) VALUES (NEW.user_id, target_badge.badge_id);
                
                -- 2. OTOMATİK BİLDİRİM GÖNDER! (YENİ)
                INSERT INTO notifications (user_id, message) 
                VALUES (NEW.user_id, 'Tebrikler! Yeni bir rozet kazandınız: ' || target_badge.badge_name);
                
                RAISE NOTICE 'Rozet verildi ve bildirim atıldı: %', NEW.username;
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

-- ==========================================
-- 6. TRIGGER: PUAN HESAPLAMA
-- ==========================================
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
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_add_points
AFTER UPDATE ON participations
FOR EACH ROW
EXECUTE FUNCTION update_points_on_completion();


-- ==========================================
-- VIEW GÜNCELLEME: view_popular_routes
-- (En sona r.route_id eklendi)
-- ==========================================
CREATE OR REPLACE VIEW view_popular_routes AS
SELECT 
    r.route_name,       -- index 0
    r.difficulty_level, -- index 1
    r.distance_km,      -- index 2
    u.username AS creator_name, -- index 3
    COUNT(DISTINCT e.event_id) AS event_count, -- index 4
    ROUND(AVG(rr.rating), 1) AS average_rating, -- index 5
    COUNT(DISTINCT rr.review_id) AS review_count, -- index 6
    r.route_id          -- index 7 (YENİ EKLENDİ)
FROM routes r
JOIN users u ON r.creator_id = u.user_id
LEFT JOIN events e ON r.route_id = e.route_id
LEFT JOIN route_reviews rr ON r.route_id = rr.route_id
GROUP BY r.route_id, r.route_name, r.difficulty_level, r.distance_km, u.username
ORDER BY event_count DESC, average_rating DESC;


-- 1. Önce eski bozuk görünümleri temizle
DROP VIEW IF EXISTS view_popular_routes;
DROP VIEW IF EXISTS view_leaderboard;

-- 2. Popüler Rotalar Görünümü (app.py burayı okuyor)
CREATE VIEW view_popular_routes AS
SELECT 
    r.route_id, 
    r.route_name, 
    r.distance_km, 
    r.difficulty_level, 
    r.estimated_duration,
    u.username,    -- Yaratan kişinin adı
    u.profile_picture_url, -- Yaratanın resmi
    COUNT(rr.review_id) as review_count, -- Kaç yorum var
    COALESCE(AVG(rr.rating), 0) as avg_rating -- Ortalama puan (Yoksa 0)
FROM routes r
JOIN users u ON r.creator_id = u.user_id
LEFT JOIN route_reviews rr ON r.route_id = rr.route_id
GROUP BY r.route_id, u.username, u.profile_picture_url;

-- 3. Liderlik Tablosu Görünümü (Anasayfa için)
CREATE VIEW view_leaderboard AS
SELECT 
    DENSE_RANK() OVER (ORDER BY u.total_points DESC) as rank,
    u.username,
    u.role,
    u.total_points,
    u.user_id,
    u.profile_picture_url
FROM users u
WHERE u.role != 'admin' -- Adminleri sıralamaya katma
ORDER BY u.total_points DESC;

-- Eski hatalı görünümü kaldır
DROP VIEW IF EXISTS view_popular_routes;

-- Yeni ve doğru sütunlu görünümü oluştur
CREATE OR REPLACE VIEW view_popular_routes AS
SELECT 
    r.route_name,       -- [0] Rota Adı
    r.difficulty_level, -- [1] Zorluk
    r.distance_km,      -- [2] Mesafe
    u.username AS creator_name, -- [3] Oluşturan
    COUNT(DISTINCT e.event_id) AS event_count, -- [4] Etkinlik Sayısı
    ROUND(AVG(COALESCE(rr.rating, 0)), 1) AS average_rating, -- [5] Puan
    COUNT(DISTINCT rr.review_id) AS review_count, -- [6] Yorum Sayısı
    r.route_id          -- [7] ID (İŞTE BU EKSİKTİ!)
FROM routes r
JOIN users u ON r.creator_id = u.user_id
LEFT JOIN events e ON r.route_id = e.route_id
LEFT JOIN route_reviews rr ON r.route_id = rr.route_id
GROUP BY r.route_id, r.route_name, r.difficulty_level, r.distance_km, u.username
ORDER BY event_count DESC, average_rating DESC;