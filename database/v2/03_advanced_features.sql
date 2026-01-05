-- ==========================================
-- 1. INDEXLER (B-TREE & PATTERN OPS)
-- ==========================================
-- Arama performansı için (ILIKE sorgularını hızlandırır)
CREATE INDEX IF NOT EXISTS idx_event_desc_btree ON events USING btree (description text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_route_name_btree ON routes USING btree (route_name text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_club_name_btree ON clubs USING btree (club_name text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_user_username_btree ON users USING btree (username text_pattern_ops);

-- Standart indexler
CREATE INDEX IF NOT EXISTS idx_stop_location ON stops(location_name);
CREATE INDEX IF NOT EXISTS idx_event_date ON events(event_date);

-- ==========================================
-- 2. VIEW: POPÜLER ROTALAR
-- ==========================================
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

-- ==========================================
-- 3. VIEW: LİDERLİK TABLOSU
-- ==========================================
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

-- ==========================================
-- 4. TRIGGER: ROZET KAZANMA + BİLDİRİM
-- ==========================================
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

-- ==========================================
-- 5. TRIGGER: PUAN HESAPLAMA
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

DROP TRIGGER IF EXISTS trg_add_points ON participations;
CREATE TRIGGER trg_add_points
AFTER UPDATE ON participations
FOR EACH ROW
EXECUTE FUNCTION update_points_on_completion();