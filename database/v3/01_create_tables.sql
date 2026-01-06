-- ==========================================
-- 1. TİP TANIMLAMALARI (ENUM TYPES)
-- ==========================================

CREATE TYPE event_status_type AS ENUM ('active', 'completed', 'cancelled', 'upcoming');
CREATE TYPE gender_type AS ENUM ('Male', 'Female', 'Unspecified');
CREATE TYPE badge_type_enum AS ENUM ('User', 'Route');
CREATE TYPE friendship_status_type AS ENUM ('pending', 'accepted', 'blocked', 'rejected');
CREATE TYPE club_role_type AS ENUM ('admin', 'member');

-- ==========================================
-- 2. ANA TABLOLAR
-- ==========================================

-- KULLANICILAR
CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR NOT NULL UNIQUE,
  password VARCHAR NOT NULL,
  email VARCHAR(150) UNIQUE,
  role VARCHAR NOT NULL DEFAULT 'user',
  total_points INTEGER DEFAULT 0,
  profile_picture_url TEXT,
  bio TEXT,
  age INTEGER,
  gender gender_type DEFAULT 'Unspecified',
  birth_date DATE,
  city VARCHAR,
  created_at TIMESTAMP DEFAULT NOW()
);

-- HOBİLER
CREATE TABLE hobbies (
    hobby_id SERIAL PRIMARY KEY,
    hobby_name VARCHAR(50) NOT NULL UNIQUE
);

-- KULLANICI HOBİLERİ
CREATE TABLE user_hobbies (
  user_hobby_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  hobby_id INTEGER REFERENCES hobbies(hobby_id) ON DELETE CASCADE,
  UNIQUE(user_id, hobby_id)
);

-- BİLDİRİMLER
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ARKADAŞLIKLAR
CREATE TABLE friendships (
    friendship_id SERIAL PRIMARY KEY,
    requester_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    addressee_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    status friendship_status_type DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(requester_id, addressee_id)
);

-- KATEGORİLER
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR NOT NULL,
    icon_url VARCHAR
);

-- KULÜPLER
CREATE TABLE clubs (
    club_id SERIAL PRIMARY KEY,
    club_name VARCHAR NOT NULL UNIQUE,
    description TEXT,
    owner_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    club_image_url TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- KULÜP ÜYELERİ
CREATE TABLE club_members (
    membership_id SERIAL PRIMARY KEY,
    club_id INTEGER REFERENCES clubs(club_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    role club_role_type DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(club_id, user_id)
);

-- KULÜP DUYURULARI
CREATE TABLE club_announcements (
    announcement_id SERIAL PRIMARY KEY,
    club_id INTEGER REFERENCES clubs(club_id) ON DELETE CASCADE,
    sender_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ROTALAR
CREATE TABLE routes (
  route_id SERIAL PRIMARY KEY,
  creator_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
  route_name VARCHAR NOT NULL,
  distance_km DECIMAL NOT NULL,
  difficulty_level VARCHAR,
  estimated_duration INTEGER, 
  created_at TIMESTAMP DEFAULT NOW()
);

-- ROTA YORUMLARI
CREATE TABLE route_reviews (
    review_id SERIAL PRIMARY KEY,
    route_id INTEGER REFERENCES routes(route_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    comment TEXT,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT NOW()
);

-- DURAKLAR
CREATE TABLE stops (
  stop_id SERIAL PRIMARY KEY,
  route_id INTEGER REFERENCES routes(route_id) ON DELETE CASCADE,
  stop_order INTEGER NOT NULL,
  location_name VARCHAR NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8)
);

-- ETKİNLİKLER
CREATE TABLE events (
  event_id SERIAL PRIMARY KEY,
  organizer_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  route_id INTEGER REFERENCES routes(route_id) ON DELETE SET NULL,
  category_id INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
  event_date TIMESTAMP NOT NULL,
  status event_status_type DEFAULT 'active',
  description TEXT,
  max_participants INTEGER DEFAULT 20,
  deadline TIMESTAMP
);

-- KATILIMLAR
CREATE TABLE participations (
  participation_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  event_id INTEGER REFERENCES events(event_id) ON DELETE CASCADE,
  join_date TIMESTAMP DEFAULT NOW(),
  is_completed BOOLEAN DEFAULT false,
  UNIQUE(user_id, event_id)
);

-- ROZETLER
CREATE TABLE badges (
    badge_id SERIAL PRIMARY KEY,
    badge_name VARCHAR NOT NULL,
    description TEXT,
    icon_url VARCHAR,
    badge_type badge_type_enum NOT NULL,
    required_value INTEGER 
);

-- KULLANICI ROZETLERİ
CREATE TABLE user_badges (
    user_badge_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    badge_id INTEGER REFERENCES badges(badge_id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

-- ROTA ROZETLERİ
CREATE TABLE route_badges (
    route_badge_id SERIAL PRIMARY KEY,
    route_id INTEGER REFERENCES routes(route_id) ON DELETE CASCADE,
    badge_id INTEGER REFERENCES badges(badge_id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(route_id, badge_id)
);

-- Varsayılan Hobileri Ekle
INSERT INTO hobbies (hobby_name) VALUES 
('Doğa Yürüyüşü'), ('Kamp'), ('Fotoğrafçılık'), ('Bisiklet'), 
('Koşu'), ('Yüzme'), ('Yoga'), ('Tarih'), ('Müzik'), ('Resim')
ON CONFLICT DO NOTHING;

-- Events tablosuna başlık sütunu ekle
ALTER TABLE events ADD COLUMN title VARCHAR(150);

-- Mevcut kayıtların başlığı boş kalmasın diye açıklamayı başlığa kopyala (Geçici çözüm)
UPDATE events SET title = SUBSTRING(description, 1, 50) WHERE title IS NULL;