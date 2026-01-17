-- ==========================================
-- 1. TİP TANIMLAMALARI (ENUM TYPES)
-- ==========================================

CREATE TYPE event_status_type AS ENUM ('active', 'completed', 'cancelled', 'upcoming');
CREATE TYPE gender_type AS ENUM ('Male', 'Female', 'Unspecified');
CREATE TYPE badge_type_enum AS ENUM ('User');
CREATE TYPE friendship_status_type AS ENUM ('pending', 'accepted', 'rejected');
CREATE TYPE club_role_type AS ENUM ('admin', 'member');

-- ==========================================
-- 2. SEQUENCES (ÖZEL SIRA TANIMLARI)
-- [MANTIK]: Ana varlıkların (Users, Clubs, Routes, Events) ID yönetimini 
-- manuel sequence ile yaparak veritabanı hakimiyetini gösteriyoruz.
-- ==========================================

CREATE SEQUENCE user_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE club_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE route_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE event_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- ==========================================
-- 3. ANA TABLOLAR
-- ==========================================

-- KULLANICILAR
CREATE TABLE users (
  user_id INTEGER PRIMARY KEY DEFAULT nextval('user_id_seq'),
  username VARCHAR NOT NULL UNIQUE,
  password VARCHAR NOT NULL,
  email VARCHAR(150),
  role VARCHAR NOT NULL DEFAULT 'user',
  total_points INTEGER DEFAULT 0,
  profile_picture_url TEXT,
  bio TEXT,
  age INTEGER,
  gender gender_type DEFAULT 'Unspecified',
  birth_date DATE,
  city VARCHAR,
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- [KISITLAR]: İsimlendirilmiş kısıtlar (Named Constraints)
  CONSTRAINT uq_users_email UNIQUE (email),
  CONSTRAINT chk_users_points_pos CHECK (total_points >= 0) -- Puan negatif olamaz
);
ALTER SEQUENCE user_id_seq OWNED BY users.user_id; -- Tablo silinirse sequence de silinsin

-- HOBİLER (Basit yapı, inline constraint yeterli)
CREATE TABLE hobbies (
    hobby_id SERIAL PRIMARY KEY,
    hobby_name VARCHAR(50) NOT NULL UNIQUE,
    icon VARCHAR(50) DEFAULT 'fas fa-star'
);

-- KULLANICI HOBİLERİ (Basit ilişki)
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

-- ARKADAŞLIKLAR (Karmaşık İlişki - Self Referencing)
CREATE TABLE friendships (
    friendship_id SERIAL PRIMARY KEY,
    requester_id INTEGER NOT NULL,
    addressee_id INTEGER NOT NULL,
    status friendship_status_type DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- [KISITLAR]: İlişki kısıtları isimlendirildi
    CONSTRAINT fk_friendship_requester FOREIGN KEY (requester_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_friendship_addressee FOREIGN KEY (addressee_id) REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- [MANTIK KISITI]: Kendine arkadaşlık isteği atamaz
    CONSTRAINT chk_no_self_friend CHECK (requester_id != addressee_id),
    UNIQUE(requester_id, addressee_id)
);

-- KATEGORİLER
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR NOT NULL,
    icon_url VARCHAR
);

-- KULÜPLER (Sequence Kullanımı)
CREATE TABLE clubs (
    club_id INTEGER PRIMARY KEY DEFAULT nextval('club_id_seq'),
    club_name VARCHAR NOT NULL UNIQUE,
    description TEXT,
    owner_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL, -- Basit tutuldu
    club_image_url TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
ALTER SEQUENCE club_id_seq OWNED BY clubs.club_id;

-- KULÜP ÜYELERİ (Many-to-Many + Composite PK)
CREATE TABLE club_members (
    club_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    role club_role_type DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT NOW(),
    
    -- [KISITLAR]: Composite PK ve FK isimlendirmeleri
    CONSTRAINT pk_club_members PRIMARY KEY (club_id, user_id),
    CONSTRAINT fk_club_member_club FOREIGN KEY (club_id) REFERENCES clubs(club_id) ON DELETE CASCADE,
    CONSTRAINT fk_club_member_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- KULÜP DUYURULARI
CREATE TABLE club_announcements (
    announcement_id SERIAL PRIMARY KEY,
    club_id INTEGER REFERENCES clubs(club_id) ON DELETE CASCADE,
    sender_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ROTALAR (Sequence ve Constraint Kullanımı)
CREATE TABLE routes (
  route_id INTEGER PRIMARY KEY DEFAULT nextval('route_id_seq'),
  creator_id INTEGER, -- FK aşağıda tanımlı
  route_name VARCHAR NOT NULL,
  distance_km DECIMAL NOT NULL,
  difficulty_level VARCHAR,
  estimated_duration INTEGER, 
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- [KISITLAR]
  CONSTRAINT chk_route_distance_pos CHECK (distance_km > 0),
  CONSTRAINT fk_route_creator FOREIGN KEY (creator_id) REFERENCES users(user_id) ON DELETE SET NULL
);
ALTER SEQUENCE route_id_seq OWNED BY routes.route_id;

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
  latitude DECIMAL(10, 8) CHECK (latitude BETWEEN -90 AND 90),
  longitude DECIMAL(11, 8) CHECK (longitude BETWEEN -180 AND 180)
);

-- ETKİNLİKLER (En Karmaşık Tablo - Sequence ve Full Constraint)
CREATE TABLE events (
  event_id INTEGER PRIMARY KEY DEFAULT nextval('event_id_seq'),
  organizer_id INTEGER, -- FK aşağıda
  route_id INTEGER,     -- FK aşağıda
  category_id INTEGER,  -- FK aşağıda
  title VARCHAR(150),
  event_date TIMESTAMP NOT NULL,
  status event_status_type DEFAULT 'active',
  description TEXT,
  max_participants INTEGER DEFAULT 20 CHECK (max_participants > 0),
  deadline TIMESTAMP,
  
  -- [KISITLAR]: Tüm ilişkiler isimlendirildi
  CONSTRAINT fk_event_organizer FOREIGN KEY (organizer_id) REFERENCES users(user_id) ON DELETE SET NULL,
  CONSTRAINT fk_event_route FOREIGN KEY (route_id) REFERENCES routes(route_id) ON DELETE SET NULL,
  CONSTRAINT fk_event_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);
ALTER SEQUENCE event_id_seq OWNED BY events.event_id;

-- KATILIMLAR (Many-to-Many + Composite PK)
CREATE TABLE participations (
  user_id INTEGER NOT NULL,
  event_id INTEGER NOT NULL,
  join_date TIMESTAMP DEFAULT NOW(),
  is_completed BOOLEAN DEFAULT false,
  
  -- [KISITLAR]
  CONSTRAINT pk_participations PRIMARY KEY (user_id, event_id),
  CONSTRAINT fk_participation_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_participation_event FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE
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
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    badge_id INTEGER REFERENCES badges(badge_id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, badge_id)
);

-- RÜTBELER
CREATE TABLE ranks (
    rank_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    min_points INTEGER NOT NULL UNIQUE,
    color_class VARCHAR(100) NOT NULL
);