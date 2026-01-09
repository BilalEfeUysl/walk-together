-- ==========================================
-- 1. TİP TANIMLAMALARI (ENUM TYPES)
-- ==========================================

CREATE TYPE event_status_type AS ENUM ('active', 'completed', 'cancelled', 'upcoming');
CREATE TYPE gender_type AS ENUM ('Male', 'Female', 'Unspecified');
CREATE TYPE badge_type_enum AS ENUM ('User'); -- 'Route' tipi kaldırıldı
CREATE TYPE friendship_status_type AS ENUM ('pending', 'accepted', 'rejected');
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
  total_points INTEGER DEFAULT 0 CHECK (total_points >= 0), -- Puan negatif olamaz
  profile_picture_url TEXT,
  bio TEXT,
  age INTEGER,
  gender gender_type DEFAULT 'Unspecified',
  birth_date DATE,
  city VARCHAR,
  created_at TIMESTAMP DEFAULT NOW()
);

-- HOBİLER (İkon sütunu eklendi)
CREATE TABLE hobbies (
    hobby_id SERIAL PRIMARY KEY,
    hobby_name VARCHAR(50) NOT NULL UNIQUE,
    icon VARCHAR(50) DEFAULT 'fas fa-star'
);

-- KULLANICI HOBİLERİ (Composite PK: user_id + hobby_id)
-- Gereksiz 'user_hobby_id' kaldırıldı.
CREATE TABLE user_hobbies (
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  hobby_id INTEGER REFERENCES hobbies(hobby_id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, hobby_id)
);

-- BİLDİRİMLER
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    related_link VARCHAR,
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

-- KULÜP ÜYELERİ (Composite PK: club_id + user_id)
CREATE TABLE club_members (
    club_id INTEGER REFERENCES clubs(club_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    role club_role_type DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (club_id, user_id)
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
  distance_km DECIMAL NOT NULL CHECK (distance_km > 0), -- Mesafe 0 olamaz
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

-- DURAKLAR (Koordinat Sınırları Eklendi)
CREATE TABLE stops (
  stop_id SERIAL PRIMARY KEY,
  route_id INTEGER REFERENCES routes(route_id) ON DELETE CASCADE,
  stop_order INTEGER NOT NULL,
  location_name VARCHAR NOT NULL,
  latitude DECIMAL(10, 8) CHECK (latitude BETWEEN -90 AND 90),
  longitude DECIMAL(11, 8) CHECK (longitude BETWEEN -180 AND 180)
);

-- ETKİNLİKLER
CREATE TABLE events (
  event_id SERIAL PRIMARY KEY,
  organizer_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
  route_id INTEGER REFERENCES routes(route_id) ON DELETE SET NULL,
  category_id INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
  title VARCHAR(150),
  event_date TIMESTAMP NOT NULL,
  status event_status_type DEFAULT 'active',
  description TEXT,
  max_participants INTEGER DEFAULT 20 CHECK (max_participants > 0),
  deadline TIMESTAMP
);

-- KATILIMLAR (Composite PK: user_id + event_id)
CREATE TABLE participations (
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  event_id INTEGER REFERENCES events(event_id) ON DELETE CASCADE,
  join_date TIMESTAMP DEFAULT NOW(),
  is_completed BOOLEAN DEFAULT false,
  PRIMARY KEY (user_id, event_id)
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

-- KULLANICI ROZETLERİ (Composite PK: user_id + badge_id)
-- Route badges tablosu silindiği için sadece bu kaldı.
CREATE TABLE user_badges (
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    badge_id INTEGER REFERENCES badges(badge_id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, badge_id)
);

-- RÜTBELER (SERIAL Düzeltildi)
CREATE TABLE ranks (
    rank_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    min_points INTEGER NOT NULL UNIQUE,
    color_class VARCHAR(100) NOT NULL
);