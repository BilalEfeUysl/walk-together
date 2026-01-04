import os
from flask import Flask, render_template, request, redirect, url_for, session, flash
from werkzeug.utils import secure_filename
from db import get_db_connection
import json

app = Flask(__name__)
app.secret_key = 'cok_gizli_ve_guvenli_bir_anahtar'

# ==========================================
# RESİM YÜKLEME AYARLARI (GÜNCELLENDİ) 🛠️
# ==========================================
# Projenin çalıştığı klasörü bulup 'static/uploads' yolunu tam adres olarak alıyoruz.
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'static', 'uploads')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Klasör yoksa oluştur (Hata almamak için)
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ==========================================
# 1. OTURUM (AUTH) İŞLEMLERİ
# ==========================================

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM users WHERE username = %s AND password = %s", (username, password))
        user = cur.fetchone()
        cur.close()
        conn.close()
        
        if user:
            session['user_id'] = user[0]
            session['username'] = user[1]
            session['role'] = user[3]
            flash('Giriş başarılı! Hoşgeldin.', 'success')
            return redirect(url_for('index'))
        else:
            flash('Hatalı kullanıcı adı veya şifre.', 'danger')
            
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == 'POST':
        username = request.form['username']
        email = request.form['email']
        password = request.form['password']
        age = request.form['age'] if request.form['age'] else None
        bio = request.form['bio']
        selected_hobbies = request.form.getlist('hobbies')

        try:
            # --- YENİ: VARSAYILAN AVATAR ---
            # Kullanıcı adının baş harflerinden avatar oluşturur (Örn: Burak -> B)
            default_pic = f"https://ui-avatars.com/api/?name={username}&background=random&color=fff&size=128"
            
            # Veritabanına bu linki kaydediyoruz
            cur.execute("""
                INSERT INTO users (username, password, email, role, age, bio, profile_picture_url) 
                VALUES (%s, %s, %s, 'user', %s, %s, %s) 
                RETURNING user_id
            """, (username, password, email, age, bio, default_pic))
            new_user_id = cur.fetchone()[0]

            for hobby_id in selected_hobbies:
                cur.execute("INSERT INTO user_hobbies (user_id, hobby_id) VALUES (%s, %s)", (new_user_id, hobby_id))

            conn.commit()
            flash('Kayıt başarılı! Giriş yapabilirsiniz.', 'success')
            return redirect(url_for('login'))
        except Exception as e:
            conn.rollback()
            print("KAYIT HATASI:", e)
            flash('Kayıt başarısız. Kullanıcı adı veya e-posta kullanımda olabilir.', 'danger')

    cur.execute("SELECT * FROM hobbies")
    all_hobbies = cur.fetchall()
    cur.close()
    conn.close()
            
    return render_template('register.html', hobbies=all_hobbies)

@app.route('/logout')
def logout():
    session.clear()
    flash('Çıkış yapıldı.', 'info')
    return redirect(url_for('index'))

# ==========================================
# 2. PROFİL DÜZENLEME (RESİM GÜNCELLEME DAHİL)
# ==========================================

@app.route('/edit_profile', methods=['GET', 'POST'])
def edit_profile():
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cur = conn.cursor()
    user_id = session['user_id']

    if request.method == 'POST':
        bio = request.form['bio']
        age = request.form['age'] if request.form['age'] else None
        selected_hobbies = request.form.getlist('hobbies')
        
        # --- RESİM YÜKLEME ---
        if 'profile_pic' in request.files:
            file = request.files['profile_pic']
            if file and allowed_file(file.filename):
                filename = secure_filename(f"user_{user_id}_{file.filename}")
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
                
                # Resim yolunu güncelle
                new_url = f"/static/uploads/{filename}"
                cur.execute("UPDATE users SET profile_picture_url = %s WHERE user_id = %s", (new_url, user_id))

        # Bilgileri Güncelle
        cur.execute("UPDATE users SET bio = %s, age = %s WHERE user_id = %s", (bio, age, user_id))
        
        # Hobileri Güncelle
        cur.execute("DELETE FROM user_hobbies WHERE user_id = %s", (user_id,))
        for hobby_id in selected_hobbies:
            cur.execute("INSERT INTO user_hobbies (user_id, hobby_id) VALUES (%s, %s)", (user_id, hobby_id))
            
        conn.commit()
        flash("Profiliniz güncellendi!", "success")
        return redirect(url_for('profile', user_id=user_id))

    # GET İsteği: Formu doldur
    # DÜZELTME: Burada da sütunları elle belirtiyoruz
    cur.execute("""
        SELECT user_id, username, password, role, total_points, age, bio, profile_picture_url 
        FROM users WHERE user_id = %s
    """, (user_id,))
    user = cur.fetchone()
    
    cur.execute("SELECT * FROM hobbies")
    all_hobbies = cur.fetchall()
    
    cur.execute("SELECT hobby_id FROM user_hobbies WHERE user_id = %s", (user_id,))
    my_hobby_ids = [row[0] for row in cur.fetchall()]

    cur.close()
    conn.close()
    return render_template('edit_profile.html', user=user, hobbies=all_hobbies, my_hobby_ids=my_hobby_ids)

# ==========================================
# 3. DİĞER SAYFALAR (AYNEN KALIYOR)
# ==========================================

@app.route('/profile/<int:user_id>')
def profile(user_id):
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        
        # DÜZELTME: Sütunları sırasıyla ve ismen çağırıyoruz ki karışıklık olmasın.
        # Sıralama: 0:id, 1:username, 2:password, 3:role, 4:total_points, 5:AGE, 6:BIO, 7:IMAGE
        cur.execute("""
            SELECT user_id, username, password, role, total_points, age, bio, profile_picture_url 
            FROM users WHERE user_id = %s;
        """, (user_id,))
        user = cur.fetchone()
        
        if not user: return "Kullanıcı bulunamadı!", 404

        # Rozetler
        cur.execute("""
            SELECT b.badge_name, b.icon_url, b.description 
            FROM user_badges ub JOIN badges b ON ub.badge_id = b.badge_id
            WHERE ub.user_id = %s;
        """, (user_id,))
        badges = cur.fetchall()

        # Hobiler
        cur.execute("""
            SELECT h.hobby_name 
            FROM user_hobbies uh 
            JOIN hobbies h ON uh.hobby_id = h.hobby_id 
            WHERE uh.user_id = %s
        """, (user_id,))
        hobbies = cur.fetchall()

        # Arkadaş Listesi
        cur.execute("""
            SELECT u.user_id, u.username, u.profile_picture_url 
            FROM friendships f
            JOIN users u ON (f.requester_id = u.user_id OR f.addressee_id = u.user_id)
            WHERE (f.requester_id = %s OR f.addressee_id = %s) AND f.status = 'accepted' AND u.user_id != %s;
        """, (user_id, user_id, user_id))
        friends = cur.fetchall()
        
        cur.close()
        conn.close()
        return render_template('profile.html', user=user, badges=badges, hobbies=hobbies, friends=friends)
    return "Hata"


@app.route('/')
def index():
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        
        cur.execute("SELECT COUNT(*) FROM users;")
        stats = {'users': cur.fetchone()[0]}
        cur.execute("SELECT COUNT(*) FROM routes;")
        stats['routes'] = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM events;")
        stats['events'] = cur.fetchone()[0]

        cur.execute("SELECT * FROM view_leaderboard LIMIT 5;")
        leaders = cur.fetchall()

        cur.execute("SELECT * FROM view_popular_routes LIMIT 4;")
        popular_routes = cur.fetchall()
        
        cur.close()
        conn.close()
        return render_template('index.html', stats=stats, leaders=leaders, popular_routes=popular_routes)
    return "Veritabanı Hatası"

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
            r_id = str(stop[0]) 
            lat = float(stop[2]) if stop[2] else 0
            lon = float(stop[3]) if stop[3] else 0
            if r_id not in map_data: map_data[r_id] = []
            map_data[r_id].append([lat, lon])
        cur.close()
        conn.close()
        return render_template('routes.html', routes=routes_list, map_data=json.dumps(map_data))
    return "Hata"

@app.route('/events')
def events():
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        category_filter = request.args.get('category')
        sql_query = """
            SELECT e.event_id, e.event_date, e.status, e.description, e.max_participants,
                   r.route_name, r.distance_km, u.username, c.category_name, c.icon_url
            FROM events e
            JOIN routes r ON e.route_id = r.route_id
            JOIN users u ON e.organizer_id = u.user_id
            JOIN categories c ON e.category_id = c.category_id
        """
        if category_filter: sql_query += f" WHERE c.category_name = '{category_filter}'"
        sql_query += " ORDER BY e.event_date ASC;"
        cur.execute(sql_query)
        events_list = cur.fetchall()
        cur.execute("SELECT category_name FROM categories;")
        categories = cur.fetchall()
        cur.close()
        conn.close()
        return render_template('events.html', events=events_list, categories=categories)
    return "Hata"

@app.route('/create', methods=['GET', 'POST'])
def create():
    if 'user_id' not in session: return redirect(url_for('login'))
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        if request.method == 'POST':
            form_type = request.form.get('form_type')
            user_id = session['user_id']
            if form_type == 'event':
                cur.execute("INSERT INTO events (organizer_id, route_id, category_id, event_date, description, status) VALUES (%s, %s, %s, %s, %s, 'upcoming')", 
                            (user_id, request.form['route_id'], request.form['category_id'], request.form['event_date'], request.form['description']))
                conn.commit()
                return redirect(url_for('events'))
            elif form_type == 'route':
                cur.execute("INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) VALUES (%s, %s, %s, %s, %s) RETURNING route_id", 
                            (user_id, request.form['route_name'], request.form['distance'], request.form['difficulty'], request.form['duration']))
                new_route_id = cur.fetchone()[0]
                if request.form['stops_json']:
                    stops_list = json.loads(request.form['stops_json'])
                    for index, stop in enumerate(stops_list):
                        loc_name = "Başlangıç" if index == 0 else "Bitiş" if index == len(stops_list)-1 else f"{index+1}. Durak"
                        cur.execute("INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES (%s, %s, %s, %s, %s)", 
                                    (new_route_id, index+1, loc_name, stop['lat'], stop['lng']))
                conn.commit()
                return redirect(url_for('routes'))
        cur.execute("SELECT route_id, route_name FROM routes")
        routes = cur.fetchall()
        cur.execute("SELECT category_id, category_name FROM categories")
        categories = cur.fetchall()
        cur.close()
        conn.close()
        return render_template('create.html', routes=routes, categories=categories)
    return "Hata"

@app.route('/leaderboard')
def leaderboard():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM view_leaderboard;")
    leaders = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('leaderboard.html', leaders=leaders)

@app.route('/notifications')
def notifications_page():
    if 'user_id' not in session: return redirect(url_for('login'))
    conn = get_db_connection()
    cur = conn.cursor()
    user_id = session['user_id']
    cur.execute("SELECT message, created_at, is_read FROM notifications WHERE user_id = %s ORDER BY created_at DESC", (user_id,))
    all_notifs = cur.fetchall()
    cur.execute("UPDATE notifications SET is_read = true WHERE user_id = %s", (user_id,))
    conn.commit()
    cur.close()
    conn.close()
    return render_template('notifications.html', notifications=all_notifs)

@app.route('/clubs')
def clubs():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""SELECT c.club_id, c.club_name, c.description, c.club_image_url, u.username, COUNT(cm.user_id) 
                   FROM clubs c JOIN users u ON c.owner_id = u.user_id LEFT JOIN club_members cm ON c.club_id = cm.club_id 
                   GROUP BY c.club_id, c.club_name, c.description, c.club_image_url, u.username ORDER BY 6 DESC;""")
    clubs_list = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('clubs.html', clubs=clubs_list)

# --- SOSYAL ÖZELLİKLER (KULÜP DETAY, ARKADAŞLIK) ---
@app.route('/join_club/<int:club_id>')
def join_club(club_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("INSERT INTO club_members (club_id, user_id) VALUES (%s, %s)", (club_id, session['user_id']))
        conn.commit()
        flash("Kulübe başarıyla katıldın!", "success")
    except:
        conn.rollback()
        flash("Zaten bu kulübe üyesiniz.", "warning")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for('club_detail', club_id=club_id))

@app.route('/club/<int:club_id>', methods=['GET', 'POST'])
def club_detail(club_id):
    conn = get_db_connection()
    cur = conn.cursor()
    if request.method == 'POST' and 'user_id' in session:
        message = request.form['message']
        sender_id = session['user_id']
        cur.execute("INSERT INTO club_announcements (club_id, sender_id, message) VALUES (%s, %s, %s)", (club_id, sender_id, message))
        cur.execute("SELECT user_id FROM club_members WHERE club_id = %s AND user_id != %s", (club_id, sender_id))
        members = cur.fetchall()
        club_name = request.form['club_name']
        notif_msg = f"📢 {club_name} kulübünde yeni bir duyuru var: {message[:20]}..."
        for member in members:
            cur.execute("INSERT INTO notifications (user_id, message) VALUES (%s, %s)", (member[0], notif_msg))
        conn.commit()
        flash("Duyuru paylaşıldı!", "success")
    cur.execute("""SELECT c.*, u.username as owner_name FROM clubs c JOIN users u ON c.owner_id = u.user_id WHERE c.club_id = %s""", (club_id,))
    club = cur.fetchone()
    is_member = False
    if 'user_id' in session:
        cur.execute("SELECT 1 FROM club_members WHERE club_id=%s AND user_id=%s", (club_id, session['user_id']))
        is_member = cur.fetchone() is not None
    cur.execute("""SELECT a.message, a.created_at, u.username, u.profile_picture_url FROM club_announcements a JOIN users u ON a.sender_id = u.user_id WHERE a.club_id = %s ORDER BY a.created_at DESC""", (club_id,))
    announcements = cur.fetchall()
    cur.execute("""SELECT u.user_id, u.username, u.profile_picture_url FROM club_members cm JOIN users u ON cm.user_id = u.user_id WHERE cm.club_id = %s""", (club_id,))
    members = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('club_detail.html', club=club, announcements=announcements, members=members, is_member=is_member)

@app.route('/friends', methods=['GET', 'POST'])
def friends():
    if 'user_id' not in session: return redirect(url_for('login'))
    conn = get_db_connection()
    cur = conn.cursor()
    user_id = session['user_id']
    search_results = []
    if request.method == 'POST' and 'search_query' in request.form:
        query = request.form['search_query']
        cur.execute("SELECT user_id, username, profile_picture_url FROM users WHERE username ILIKE %s AND user_id != %s", (f'%{query}%', user_id))
        search_results = cur.fetchall()
    cur.execute("""SELECT f.friendship_id, u.username, u.profile_picture_url, u.user_id FROM friendships f JOIN users u ON f.requester_id = u.user_id WHERE f.addressee_id = %s AND f.status = 'pending'""", (user_id,))
    pending_requests = cur.fetchall()
    cur.execute("""SELECT u.username, u.profile_picture_url, u.user_id FROM friendships f JOIN users u ON (f.requester_id = u.user_id OR f.addressee_id = u.user_id) WHERE (f.requester_id = %s OR f.addressee_id = %s) AND f.status = 'accepted' AND u.user_id != %s""", (user_id, user_id, user_id))
    my_friends = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('friends.html', search_results=search_results, pending_requests=pending_requests, my_friends=my_friends)

@app.route('/add_friend/<int:target_id>')
def add_friend(target_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("INSERT INTO friendships (requester_id, addressee_id, status) VALUES (%s, %s, 'pending')", (session['user_id'], target_id))
        cur.execute("INSERT INTO notifications (user_id, message) VALUES (%s, %s)", (target_id, f"{session['username']} sana arkadaşlık isteği gönderdi."))
        conn.commit()
        flash("Arkadaşlık isteği gönderildi.", "success")
    except:
        conn.rollback()
        flash("İstek zaten gönderilmiş veya zaten arkadaşsınız.", "warning")
    cur.close()
    conn.close()
    return redirect(url_for('friends'))

@app.route('/accept_friend/<int:friendship_id>')
def accept_friend(friendship_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("UPDATE friendships SET status = 'accepted' WHERE friendship_id = %s", (friendship_id,))
    cur.execute("SELECT requester_id FROM friendships WHERE friendship_id = %s", (friendship_id,))
    requester_id = cur.fetchone()[0]
    cur.execute("INSERT INTO notifications (user_id, message) VALUES (%s, %s)", (requester_id, f"{session['username']} arkadaşlık isteğini kabul etti! 🎉"))
    conn.commit()
    cur.close()
    conn.close()
    flash("Artık arkadaşsınız!", "success")
    return redirect(url_for('friends'))

@app.route('/route/<int:route_id>', methods=['GET', 'POST'])
def route_detail_full(route_id): # Yukarıda zaten vardı, bu tam fonksiyon
    return route_detail(route_id)

@app.context_processor
def inject_notifications():
    notifications = []
    unread_count = 0
    if 'user_id' in session:
        conn = get_db_connection()
        if conn:
            cur = conn.cursor()
            user_id = session['user_id']
            cur.execute("SELECT message, created_at, is_read FROM notifications WHERE user_id = %s ORDER BY created_at DESC LIMIT 5", (user_id,))
            notifications = cur.fetchall()
            cur.execute("SELECT COUNT(*) FROM notifications WHERE user_id = %s AND is_read = false", (user_id,))
            unread_count = cur.fetchone()[0]
            cur.close()
            conn.close()
    return dict(notifications=notifications, unread_count=unread_count)

if __name__ == '__main__':
    app.run(debug=True)