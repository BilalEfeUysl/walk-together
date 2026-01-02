from flask import Flask, render_template, request # request eklendi (Filtreleme için)
from db import get_db_connection
import json

app = Flask(__name__)

# --- ANA SAYFA ---
@app.route('/')
def index():
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        
        # İstatistikler
        cur.execute("SELECT COUNT(*) FROM users;")
        user_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM routes;")
        route_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM events;")
        event_count = cur.fetchone()[0]
        stats = {'users': user_count, 'routes': route_count, 'events': event_count}

        # Liderlik Tablosu
        cur.execute("SELECT * FROM view_leaderboard LIMIT 5;")
        leaders = cur.fetchall()

        # Popüler Rotalar
        cur.execute("SELECT * FROM view_popular_routes LIMIT 4;")
        popular_routes = cur.fetchall()
        
        cur.close()
        conn.close()
        return render_template('index.html', stats=stats, leaders=leaders, popular_routes=popular_routes)
    else:
        return "Veritabanı hatası"

# --- ROTALAR SAYFASI ---
@app.route('/routes')
def routes():
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM view_popular_routes;") 
        routes_list = cur.fetchall()
        
        cur.execute("SELECT route_id, location_name, latitude, longitude FROM stops ORDER BY route_id, stop_order;")
        stops = cur.fetchall()
        
        map_data = {}
        for stop in stops:
            # View sorgusundaki sırayla eşleşmesi için ID yerine index mantığı kullanmıştık front-end'de.
            # Burada ID bazlı grupluyoruz.
            r_id = str(stop[0]) 
            lat = float(stop[2]) if stop[2] else 0
            lon = float(stop[3]) if stop[3] else 0
            
            if r_id not in map_data:
                map_data[r_id] = []
            map_data[r_id].append([lat, lon])
            
        cur.close()
        conn.close()
        return render_template('routes.html', routes=routes_list, map_data=json.dumps(map_data))
    else:
        return "Veritabanı hatası"

# --- YENİ: ETKİNLİKLER SAYFASI ---
@app.route('/events')
def events():
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()

        # Kategori filtresi var mı? (?category=Doğa Yürüyüşü gibi)
        category_filter = request.args.get('category')

        # SQL Sorgusu: Events + Routes + Users + Categories
        sql_query = """
            SELECT 
                e.event_id,
                e.event_date,
                e.status,
                e.description,
                e.max_participants,
                r.route_name,
                r.distance_km,
                u.username,
                c.category_name,
                c.icon_url
            FROM events e
            JOIN routes r ON e.route_id = r.route_id
            JOIN users u ON e.organizer_id = u.user_id
            JOIN categories c ON e.category_id = c.category_id
        """

        # Eğer filtre varsa WHERE ekle
        if category_filter:
            sql_query += f" WHERE c.category_name = '{category_filter}'"
        
        sql_query += " ORDER BY e.event_date ASC;"

        cur.execute(sql_query)
        events_list = cur.fetchall()

        # Kategorileri de çekelim (Filtre menüsü için)
        cur.execute("SELECT category_name FROM categories;")
        categories = cur.fetchall()

        cur.close()
        conn.close()
        return render_template('events.html', events=events_list, categories=categories)
    else:
        return "Veritabanı hatası"

# --- YENİ: PROFİL SAYFASI ---
@app.route('/profile/<int:user_id>')
def profile(user_id):
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()

        # 1. Kullanıcı Temel Bilgilerini Çek
        cur.execute("SELECT * FROM users WHERE user_id = %s;", (user_id,))
        user = cur.fetchone()

        if not user:
            return "Kullanıcı bulunamadı!", 404

        # 2. Rozetleri Çek (JOIN işlemi)
        cur.execute("""
            SELECT b.badge_name, b.icon_url, b.description 
            FROM user_badges ub
            JOIN badges b ON ub.badge_id = b.badge_id
            WHERE ub.user_id = %s;
        """, (user_id,))
        badges = cur.fetchall()

        # 3. Hobileri Çek
        cur.execute("SELECT hobby_name FROM user_hobbies WHERE user_id = %s;", (user_id,))
        hobbies = cur.fetchall()

        # 4. Arkadaşları Çek (Karmaşık Sorgu: Hem gönderen hem alan olabilir)
        # Eğer requester ben isem addressee arkadaşımdır, tam tersi de geçerli.
        cur.execute("""
            SELECT u.user_id, u.username, u.profile_picture_url 
            FROM friendships f
            JOIN users u ON (f.requester_id = u.user_id OR f.addressee_id = u.user_id)
            WHERE (f.requester_id = %s OR f.addressee_id = %s)
              AND f.status = 'accepted'
              AND u.user_id != %s; -- Kendimi listeleme
        """, (user_id, user_id, user_id))
        friends = cur.fetchall()

        cur.close()
        conn.close()

        return render_template('profile.html', user=user, badges=badges, hobbies=hobbies, friends=friends)
    else:
        return "Veritabanı hatası"


# --- YENİ: ROTA DETAY VE YORUM YAPMA ---
@app.route('/route/<int:route_id>', methods=['GET', 'POST'])
def route_detail(route_id):
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()

        # --- FORM GÖNDERİLDİYSE (YORUM EKLEME) ---
        if request.method == 'POST':
            # Formdan gelen verileri al
            comment = request.form['comment']
            rating = request.form['rating']
            user_id = 2  # DEMO: Şimdilik herkes 'Ayşe' olarak yorum yapsın
            
            # Veritabanına Ekle
            try:
                cur.execute("""
                    INSERT INTO route_reviews (route_id, user_id, comment, rating)
                    VALUES (%s, %s, %s, %s)
                """, (route_id, user_id, comment, rating))
                conn.commit() # Değişikliği kaydet
            except Exception as e:
                print("Hata:", e)
                conn.rollback() # Hata olursa geri al

        # --- SAYFA VERİLERİNİ ÇEKME ---
        
        # 1. Rota Detaylarını Çek
        cur.execute("""
            SELECT r.*, u.username, u.profile_picture_url 
            FROM routes r 
            JOIN users u ON r.creator_id = u.user_id 
            WHERE r.route_id = %s
        """, (route_id,))
        route = cur.fetchone()

        # 2. Durakları Çek
        cur.execute("SELECT * FROM stops WHERE route_id = %s ORDER BY stop_order", (route_id,))
        stops = cur.fetchall()

        # 3. Yorumları Çek (Kullanıcı bilgisiyle beraber)
        cur.execute("""
            SELECT r.rating, r.comment, r.created_at, u.username, u.profile_picture_url, u.user_id
            FROM route_reviews r
            JOIN users u ON r.user_id = u.user_id
            WHERE r.route_id = %s
            ORDER BY r.created_at DESC
        """, (route_id,))
        reviews = cur.fetchall()

        cur.close()
        conn.close()
        return render_template('route_detail.html', route=route, stops=stops, reviews=reviews)
    else:
        return "Veritabanı hatası"
    
# --- YENİ: KULÜPLER SAYFASI ---
@app.route('/clubs')
def clubs():
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()

        # Kulüpleri listele + Başkan adını çek + Üye sayısını say (GROUP BY)
        query = """
            SELECT 
                c.club_id, 
                c.club_name, 
                c.description, 
                c.club_image_url, 
                u.username, -- Başkanın adı
                COUNT(cm.user_id) as member_count -- Üye sayısı
            FROM clubs c
            JOIN users u ON c.owner_id = u.user_id
            LEFT JOIN club_members cm ON c.club_id = cm.club_id
            GROUP BY c.club_id, c.club_name, c.description, c.club_image_url, u.username
            ORDER BY member_count DESC; -- En popüler kulüp en üstte
        """
        
        cur.execute(query)
        clubs_list = cur.fetchall()

        cur.close()
        conn.close()
        return render_template('clubs.html', clubs=clubs_list)
    else:
        return "Veritabanı hatası"

# --- HER SAYFADA ÇALIŞACAK FONKSİYON (CONTEXT PROCESSOR) ---
@app.context_processor
def inject_notifications():
    conn = get_db_connection()
    notifications = []
    unread_count = 0
    
    if conn:
        cur = conn.cursor()
        # DEMO: Ayşe (ID=2) giriş yapmış gibi varsayıyoruz
        user_id = 2 
        
        # 1. Bildirimleri Çek (En yeniden eskiye)
        cur.execute("""
            SELECT message, created_at, is_read 
            FROM notifications 
            WHERE user_id = %s 
            ORDER BY created_at DESC 
            LIMIT 5
        """, (user_id,))
        notifications = cur.fetchall()
        
        # 2. Okunmamışları Say (Kırmızı yuvarlak içindeki sayı)
        cur.execute("SELECT COUNT(*) FROM notifications WHERE user_id = %s AND is_read = false", (user_id,))
        unread_count = cur.fetchone()[0]
        
        cur.close()
        conn.close()
        
    # Bu değişkenler artık base.html dahil her yerde kullanılabilir!
    return dict(notifications=notifications, unread_count=unread_count)

# --- YENİ: LİDERLİK SIRALAMASI SAYFASI ---
@app.route('/leaderboard')
def leaderboard():
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        
        # View tablomuzu kullanarak sıralamayı çekiyoruz
        # view_leaderboard: siralama, username, role, total_points, user_id
        cur.execute("SELECT * FROM view_leaderboard;") 
        leaders = cur.fetchall()
        
        cur.close()
        conn.close()
        return render_template('leaderboard.html', leaders=leaders)
    else:
        return "Veritabanı hatası"

if __name__ == '__main__':
    app.run(debug=True)

