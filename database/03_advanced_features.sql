-- ==========================================
-- 1. VIEW (SANAL TABLO) [Proje Madde 6]
-- ==========================================
-- Amaç: Kullanıcıların puan durumunu (Liderlik Tablosu) gösteren bir View.
-- Arayüzde "Liderler" sayfasına tıklandığında bu çalışacak.
CREATE OR REPLACE VIEW view_leaderboard AS
SELECT 
    RANK() OVER (ORDER BY total_points DESC) as siralama,
    username,
    role,
    total_points
FROM users
WHERE role != 'admin'; -- Adminleri sıralamaya katmıyoruz

-- ==========================================
-- 2. INDEX (PERFORMANS) [Proje Madde 7]
-- ==========================================
-- Amaç: Rota isimlerine göre arama yapıldığında (LIKE %...%) hızlı sonuç dönmesi.
CREATE INDEX idx_route_name ON routes(route_name);

-- ==========================================
-- 3. KARMAŞIK SORGULAR [Proje Madde 9 & 10]
-- ==========================================

-- A) Aggregate & Having (Madde 10):
-- En az 2 tane "Zor" (Hard) seviye rota oluşturmuş kullanıcıları listele.
-- (GROUP BY ve HAVING kullanımı)
SELECT u.username, COUNT(r.route_id) as zor_rota_sayisi
FROM users u
JOIN routes r ON u.user_id = r.creator_id
WHERE r.difficulty_level = 'Hard'
GROUP BY u.username
HAVING COUNT(r.route_id) >= 2;

-- B) Union / Intersect / Except (Madde 9):
-- Hem etkinlik düzenleyen (Organizer) HEM DE etkinliğe katılan (Participant) aktif kullanıcılar.
-- (INTERSECT Kullanımı)
SELECT organizer_id FROM events
INTERSECT
SELECT user_id FROM participations;

-- ==========================================
-- 4. FONKSİYONLAR (STORED PROCEDURES) [Proje Madde 11]
-- ==========================================

-- Fonksiyon 1: Parametre alan ve değer döndüren basit fonksiyon.
-- Görevi: Bir kullanıcının tamamladığı toplam mesafe (KM) bilgisini döner.
CREATE OR REPLACE FUNCTION get_user_total_distance(p_user_id INTEGER)
RETURNS DECIMAL AS $$
DECLARE
    total_dist DECIMAL := 0;
BEGIN
    SELECT COALESCE(SUM(r.distance_km), 0)
    INTO total_dist
    FROM participations p
    JOIN events e ON p.event_id = e.event_id
    JOIN routes r ON e.route_id = r.route_id
    WHERE p.user_id = p_user_id AND p.is_completed = true;
    
    RETURN total_dist;
END;
$$ LANGUAGE plpgsql;

-- Fonksiyon 2: RECORD ve CURSOR Kullanımı (Madde 11 - Zorunlu)
-- Görevi: Belirli bir zorluk seviyesindeki rotaları tek tek gezip raporlayan fonksiyon.
CREATE OR REPLACE FUNCTION analyze_routes_by_difficulty(p_level VARCHAR)
RETURNS TEXT AS $$
DECLARE
    -- Cursor Tanımı
    route_cursor CURSOR FOR SELECT route_name, distance_km FROM routes WHERE difficulty_level = p_level;
    route_record RECORD; -- Record Tanımı
    result_text TEXT := '';
BEGIN
    OPEN route_cursor;
    
    LOOP
        FETCH route_cursor INTO route_record;
        EXIT WHEN NOT FOUND;
        
        -- Her satır için işlem yapılıyor
        result_text := result_text || 'Rota: ' || route_record.route_name || ' (' || route_record.distance_km || ' km) - ';
    END LOOP;
    
    CLOSE route_cursor;
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Fonksiyon 3: Tablo Döndüren Fonksiyon
-- Görevi: Tarihi geçmiş ama hala 'active' görünen etkinlikleri bulur.
CREATE OR REPLACE FUNCTION get_expired_active_events()
RETURNS TABLE(event_name text, event_date timestamp) AS $$
BEGIN
    RETURN QUERY 
    SELECT ('Etkinlik #' || event_id)::text, e.event_date
    FROM events e
    WHERE e.event_date < NOW() AND e.status = 'active';
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- 5. TRIGGERLAR (TETİKLEYİCİLER) [Proje Madde 12]
-- ==========================================

-- Trigger 1: Puan Sistemi
-- Senaryo: Bir kullanıcı etkinliği tamamladığında (is_completed = true olduğunda)
-- otomatik olarak puanı artsın. (1 km = 10 Puan)
CREATE OR REPLACE FUNCTION update_points_on_completion()
RETURNS TRIGGER AS $$
DECLARE
    route_km DECIMAL;
    points_to_add INTEGER;
BEGIN
    -- Sadece tamamlandı olarak işaretlendiyse çalış
    IF NEW.is_completed = true AND OLD.is_completed = false THEN
        -- Rotanın mesafesini bul
        SELECT r.distance_km INTO route_km
        FROM events e
        JOIN routes r ON e.route_id = r.route_id
        WHERE e.event_id = NEW.event_id;
        
        -- Puan hesapla (Örn: 5.5 km -> 55 puan)
        points_to_add := CAST(route_km * 10 AS INTEGER);
        
        -- Kullanıcının puanını güncelle
        UPDATE users SET total_points = total_points + points_to_add
        WHERE user_id = NEW.user_id;
        
        -- Bilgilendirme (Log veya Console) - Hocanın istediği mesaj kısmı
        RAISE NOTICE 'Kullanıcı % puan kazandı: %', NEW.user_id, points_to_add;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_add_points
AFTER UPDATE ON participations
FOR EACH ROW
EXECUTE FUNCTION update_points_on_completion();

-- Trigger 2: Silme Kısıtı (Constraint Trigger)
-- Senaryo: İçinde aktif etkinlik bulunan bir Rota silinemez!
CREATE OR REPLACE FUNCTION prevent_route_deletion()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM events WHERE route_id = OLD.route_id AND status = 'active') THEN
        RAISE EXCEPTION 'Bu rotada aktif bir etkinlik olduğu için silinemez!';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_route_delete
BEFORE DELETE ON routes
FOR EACH ROW
EXECUTE FUNCTION prevent_route_deletion();