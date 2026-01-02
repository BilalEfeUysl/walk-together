-- ==========================================
-- 1. TİP TANIMLAMALARI (ENUM TYPES)
-- ==========================================
CREATE TYPE event_status_type AS ENUM ('active', 'completed', 'cancelled', 'upcoming');
CREATE TYPE gender_type AS ENUM ('Male', 'Female', 'Unspecified');
CREATE TYPE badge_type_enum AS ENUM ('User', 'Route');
CREATE TYPE friendship_status_type AS ENUM ('pending', 'accepted', 'blocked');
CREATE TYPE club_role_type AS ENUM ('admin', 'member');

-- ==========================================
-- 2. ANA TABLOLAR
-- ==========================================

-- KULLANICILAR
CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR NOT NULL UNIQUE,
  password VARCHAR NOT NULL,
  role VARCHAR NOT NULL DEFAULT 'user',
  total_points INTEGER DEFAULT 0,
  profile_picture_url TEXT,
  bio TEXT,
  gender gender_type DEFAULT 'Unspecified',
  birth_date DATE,
  city VARCHAR,
  created_at TIMESTAMP DEFAULT NOW()
);

-- BİLDİRİMLER (YENİ) 🔔
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

-- HOBİLER
CREATE TABLE user_hobbies (
  hobby_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  hobby_name VARCHAR NOT NULL
);

-- KATEGORİLER
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR NOT NULL,
    icon_url VARCHAR
);

-- KULÜPLER (DÜZELTİLDİ: ON DELETE SET NULL) 🛡️
CREATE TABLE clubs (
    club_id SERIAL PRIMARY KEY,
    club_name VARCHAR NOT NULL UNIQUE,
    description TEXT,
    -- Başkan silinirse kulüp silinmesin, başkan koltuğu boş kalsın:
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

-- ROTALAR
CREATE TABLE routes (
  route_id SERIAL PRIMARY KEY,
  creator_id INTEGER REFERENCES users(user_id), -- Rota sahibi silinirse rota kalsın mı? Genelde silinir veya SET NULL yapılır. Şimdilik böyle kalsın.
  route_name VARCHAR NOT NULL,
  distance_km DECIMAL NOT NULL,
  difficulty_level VARCHAR,
  estimated_duration INTEGER, 
  created_at TIMESTAMP DEFAULT NOW()
);

-- ROTA YORUMLARI VE PUANLARI (YENİ) 💬
CREATE TABLE route_reviews (
    review_id SERIAL PRIMARY KEY,
    route_id INTEGER REFERENCES routes(route_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    comment TEXT,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5), -- 1 ile 5 arası puan zorunlu
    created_at TIMESTAMP DEFAULT NOW()
);

-- DURAKLAR
CREATE TABLE stops (
  stop_id SERIAL PRIMARY KEY,
  route_id INTEGER REFERENCES routes(route_id) ON DELETE CASCADE,
  stop_order INTEGER NOT NULL, -- 1. durak, 2. durak...
  location_name VARCHAR NOT NULL,
  latitude DECIMAL(10, 8),  -- Örn: 41.008237
  longitude DECIMAL(11, 8)  -- Örn: 28.978358
);

-- ETKİNLİKLER
CREATE TABLE events (
  event_id SERIAL PRIMARY KEY,
  organizer_id INTEGER REFERENCES users(user_id),
  route_id INTEGER REFERENCES routes(route_id),
  category_id INTEGER REFERENCES categories(category_id),
  event_date TIMESTAMP NOT NULL,
  status event_status_type DEFAULT 'active',
  description TEXT,
  max_participants INTEGER DEFAULT 20,
  deadline TIMESTAMP
);

-- KATILIMLAR
CREATE TABLE participations (
  participation_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(user_id),
  event_id INTEGER REFERENCES events(event_id) ON DELETE CASCADE,
  join_date TIMESTAMP DEFAULT NOW(),
  is_completed BOOLEAN DEFAULT false
);

-- 3. Foreign Key Tanımları

-- ROZETLER
CREATE TABLE badges (
    badge_id SERIAL PRIMARY KEY,
    badge_name VARCHAR NOT NULL,
    description TEXT,
    icon_url VARCHAR,
    badge_type badge_type_enum NOT NULL,
    required_value INTEGER 
);

CREATE TABLE user_badges (
    user_badge_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    badge_id INTEGER REFERENCES badges(badge_id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

CREATE TABLE route_badges (
    route_badge_id SERIAL PRIMARY KEY,
    route_id INTEGER REFERENCES routes(route_id) ON DELETE CASCADE,
    badge_id INTEGER REFERENCES badges(badge_id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(route_id, badge_id)
);