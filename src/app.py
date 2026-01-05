import os
from flask import Flask, render_template, request, redirect, url_for, session, flash
from werkzeug.utils import secure_filename
from db import get_db_connection
import json

app = Flask(__name__)
app.secret_key = 'cok_gizli_ve_guvenli_bir_anahtar'

# ==========================================
# RESİM YÜKLEME AYARLARI
# ==========================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'static', 'uploads')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

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
            default_pic = f"https://ui-avatars.com/api/?name={username}&background=random&color=fff&size=128"
            
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
# 2. PROFİL DÜZENLEME
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
        
        if 'profile_pic' in request.files:
            file = request.files['profile_pic']
            if file and allowed_file(file.filename):
                filename = secure_filename(f"user_{user_id}_{file.filename}")
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
                new_url = f"/static/uploads/{filename}"
                cur.execute("UPDATE users SET profile_picture_url = %s WHERE user_id = %s", (new_url, user_id))

        cur.execute("UPDATE users SET bio = %s, age = %s WHERE user_id = %s", (bio, age, user_id))
        
        cur.execute("DELETE FROM user_hobbies WHERE user_id = %s", (user_id,))
        for hobby_id in selected_hobbies:
            cur.execute("INSERT INTO user_hobbies (user_id, hobby_id) VALUES (%s, %s)", (user_id, hobby_id))
            
        conn.commit()
        flash("Profiliniz güncellendi!", "success")
        return redirect(url_for('profile', user_id=user_id))

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
# 3. ANA SAYFALAR
# ==========================================

@app.route('/profile/<int:user_id>')
def profile(user_id):
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        
        # 1. Kullanıcı Bilgileri
        cur.execute("""
            SELECT user_id, username, password, role, total_points, age, bio, profile_picture_url 
            FROM users WHERE user_id = %s;
        """, (user_id,))
        user = cur.fetchone()
        
        if not user: return "Kullanıcı bulunamadı!", 404

        # 2. Rozetler
        cur.execute("""
            SELECT b.badge_name, b.icon_url, b.description 
            FROM user_badges ub JOIN badges b ON ub.badge_id = b.badge_id
            WHERE ub.user_id = %s;
        """, (user_id,))
        badges = cur.fetchall()

        # 3. Hobiler
        cur.execute("""
            SELECT h.hobby_name 
            FROM user_hobbies uh 
            JOIN hobbies h ON uh.hobby_id = h.hobby_id 
            WHERE uh.user_id = %s
        """, (user_id,))
        hobbies = cur.fetchall()

        # 4. Arkadaş Listesi
        cur.execute("""
            SELECT u.user_id, u.username, u.profile_picture_url 
            FROM friendships f
            JOIN users u ON (f.requester_id = u.user_id OR f.addressee_id = u.user_id)
            WHERE (f.requester_id = %s OR f.addressee_id = %s) AND f.status = 'accepted' AND u.user_id != %s;
        """, (user_id, user_id, user_id))
        friends = cur.fetchall()

        # 5. OLUŞTURDUĞU ROTALAR (YENİ EKLENDİ)
        cur.execute("""
            SELECT route_id, route_name, distance_km, difficulty_level 
            FROM routes 
            WHERE creator_id = %s 
            ORDER BY route_id DESC
        """, (user_id,))
        created_routes = cur.fetchall()
        
        cur.close()
        conn.close()
        # created_routes değişkenini HTML'e gönderiyoruz
        return render_template('profile.html', user=user, badges=badges, hobbies=hobbies, friends=friends, created_routes=created_routes)
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

# app.py içindeki routes fonksiyonunu bununla değiştir:
@app.route('/routes')
def routes():
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        
        search_query = request.args.get('q', '')
        
        # View üzerinden arama yapıyoruz
        sql = "SELECT * FROM view_popular_routes"
        params = []
        
        if search_query:
            # view_popular_routes içindeki route_name [0. index]
            sql += " WHERE route_name ILIKE %s"
            params.append(f"%{search_query}%")
            
        cur.execute(sql, tuple(params))
        routes_list = cur.fetchall()
        
        # Harita verisi (Arama olsa bile haritada hepsi görünsün veya filtrelensin tercihi)
        # Şimdilik harita verisini yine tüm duraklardan çekiyoruz ki harita boş kalmasın
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
        return render_template('routes.html', routes=routes_list, map_data=json.dumps(map_data), search_query=search_query)
    return "Hata"

# --- ETKİNLİĞE KATILMA ---
@app.route('/join_event/<int:event_id>')
def join_event(event_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        cur.execute("SELECT count(*) FROM participations WHERE event_id = %s", (event_id,))
        current_count = cur.fetchone()[0]
        cur.execute("SELECT max_participants FROM events WHERE event_id = %s", (event_id,))
        max_limit = cur.fetchone()[0]
        
        if current_count >= max_limit:
            flash("Malesef kontenjan dolu.", "warning")
            return redirect(url_for('events'))

        cur.execute("INSERT INTO participations (user_id, event_id) VALUES (%s, %s)", (session['user_id'], event_id))
        conn.commit()
        flash("Etkinliğe başarıyla kaydoldun! 🏃‍♂️", "success")

    except Exception as e:
        conn.rollback()
        print("KATILMA HATASI:", e)
        flash("Zaten bu etkinliğe katılıyorsunuz.", "info")
        
    finally:
        cur.close()
        conn.close()
        
    return redirect(url_for('events'))

# --- ETKİNLİK LİSTELEME ---
# app.py içindeki events fonksiyonunu bununla değiştir:
@app.route('/events', methods=['GET'])
def events():
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        
        # Süresi dolanları güncelle
        cur.execute("UPDATE events SET status = 'completed' WHERE event_date < NOW() AND status IN ('active', 'upcoming')")
        conn.commit()

        # ARAMA PARAMETRELERİ
        search_query = request.args.get('q', '')
        category_filter = request.args.get('category')
        
        # Temel Sorgu
        base_query = """
            SELECT e.event_id, e.event_date, e.status, e.description, e.max_participants,
                   r.route_name, r.distance_km, u.username, c.category_name, c.icon_url,
                   COUNT(p.participation_id) as current_count,
                   e.organizer_id
            FROM events e
            JOIN routes r ON e.route_id = r.route_id
            JOIN users u ON e.organizer_id = u.user_id
            JOIN categories c ON e.category_id = c.category_id
            LEFT JOIN participations p ON e.event_id = p.event_id
            WHERE e.status != 'completed' 
        """
        
        params = []
        
        # 1. Arama Filtresi (Hem açıklama hem rota isminde arar)
        if search_query:
            base_query += " AND (e.description ILIKE %s OR r.route_name ILIKE %s)"
            # İki yere de aynı kelimeyi gönderiyoruz
            term = f"%{search_query}%"
            params.extend([term, term])
            
        # 2. Kategori Filtresi
        if category_filter:
            base_query += " AND c.category_name = %s"
            params.append(category_filter)
        
        base_query += """
            GROUP BY e.event_id, r.route_name, r.distance_km, u.username, c.category_name, c.icon_url, e.organizer_id
            ORDER BY e.event_date ASC;
        """
        
        cur.execute(base_query, tuple(params))
        events_list = cur.fetchall()
        
        cur.execute("SELECT category_name FROM categories;")
        categories = cur.fetchall()

        my_participations = []
        if 'user_id' in session:
            cur.execute("SELECT event_id FROM participations WHERE user_id = %s", (session['user_id'],))
            my_participations = [row[0] for row in cur.fetchall()]
        
        cur.close()
        conn.close()
        return render_template('events.html', events=events_list, categories=categories, my_events=my_participations, search_query=search_query)
    return "Hata"

# --- ETKİNLİK İPTAL ETME ---
@app.route('/cancel_event/<int:event_id>')
def cancel_event(event_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    cur.execute("SELECT organizer_id, description FROM events WHERE event_id = %s", (event_id,))
    event = cur.fetchone()
    
    if event and event[0] == session['user_id']:
        cur.execute("SELECT user_id FROM participations WHERE event_id = %s", (event_id,))
        participants = cur.fetchall()
        
        cur.execute("UPDATE events SET status = 'cancelled' WHERE event_id = %s", (event_id,))
        
        notif_msg = f"⚠️ '{event[1][:20]}...' etkinliği organizatör tarafından iptal edildi."
        for p in participants:
            if p[0] != session['user_id']:
                cur.execute("INSERT INTO notifications (user_id, message) VALUES (%s, %s)", (p[0], notif_msg))
        
        conn.commit()
        flash("Etkinlik iptal edildi ve katılımcılara bildirim gönderildi.", "info")
    else:
        flash("Bu işlem için yetkiniz yok.", "danger")
        
    cur.close()
    conn.close()
    return redirect(url_for('events'))

@app.route('/create', methods=['GET', 'POST'])
def create():
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        
        if request.method == 'POST':
            user_id = session['user_id']
            form_type = request.form.get('form_type')
            
            try:
                if form_type == 'event':
                    route_selection_mode = request.form.get('route_selection_mode')
                    final_route_id = None
                    
                    if route_selection_mode == 'new':
                        r_name = request.form['new_route_name']
                        r_dist = request.form['distance']
                        r_diff = request.form['difficulty']
                        r_dur = request.form['duration']
                        
                        cur.execute("""
                            INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
                            VALUES (%s, %s, %s, %s, %s) RETURNING route_id
                        """, (user_id, r_name, r_dist, r_diff, r_dur))
                        final_route_id = cur.fetchone()[0]
                        
                        if request.form['stops_json']:
                            stops_list = json.loads(request.form['stops_json'])
                            for index, stop in enumerate(stops_list):
                                loc_name = "Başlangıç" if index == 0 else "Bitiş" if index == len(stops_list)-1 else f"{index+1}. Durak"
                                cur.execute("INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES (%s, %s, %s, %s, %s)", 
                                            (final_route_id, index+1, loc_name, stop['lat'], stop['lng']))
                    else:
                        final_route_id = request.form['route_id']

                    cur.execute("""
                        INSERT INTO events (organizer_id, route_id, category_id, event_date, description, status, max_participants) 
                        VALUES (%s, %s, %s, %s, %s, 'upcoming', %s)
                    """, (user_id, final_route_id, request.form['category_id'], request.form['event_date'], request.form['description'], request.form['max_participants']))
                    
                    conn.commit()
                    flash('Etkinlik oluşturuldu! 🎉', 'success')
                    return redirect(url_for('events'))

                elif form_type == 'route_only':
                    cur.execute("""
                        INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration) 
                        VALUES (%s, %s, %s, %s, %s) RETURNING route_id
                    """, (user_id, request.form['route_name'], request.form['distance'], request.form['difficulty'], request.form['duration']))
                    new_route_id = cur.fetchone()[0]
                    
                    if request.form['stops_json']:
                        stops_list = json.loads(request.form['stops_json'])
                        for index, stop in enumerate(stops_list):
                            loc_name = "Başlangıç" if index == 0 else "Bitiş" if index == len(stops_list)-1 else f"{index+1}. Durak"
                            cur.execute("INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude) VALUES (%s, %s, %s, %s, %s)", 
                                        (new_route_id, index+1, loc_name, stop['lat'], stop['lng']))
                    
                    conn.commit()
                    flash('Rota başarıyla eklendi.', 'success')
                    return redirect(url_for('routes'))

            except Exception as e:
                conn.rollback()
                print("HATA:", e)
                flash(f'Bir hata oluştu: {e}', 'danger')

        cur.execute("SELECT route_id, route_name, distance_km FROM routes ORDER BY route_id DESC")
        routes = cur.fetchall()
        cur.execute("SELECT category_id, category_name FROM categories")
        categories = cur.fetchall()
        
        cur.close()
        conn.close()
        return render_template('create.html', routes=routes, categories=categories)
    
    return "Veritabanı Bağlantı Hatası"

@app.route('/leaderboard')
def leaderboard():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM view_leaderboard;")
    leaders = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('leaderboard.html', leaders=leaders)

# --- BİLDİRİMLER SAYFASI (GÜNCELLENDİ: ID ÇEKİLİYOR) ---
@app.route('/notifications')
def notifications_page():
    if 'user_id' not in session: return redirect(url_for('login'))
    conn = get_db_connection()
    cur = conn.cursor()
    user_id = session['user_id']
    # notification_id (4. sütun) eklendi
    cur.execute("SELECT message, created_at, is_read, notification_id FROM notifications WHERE user_id = %s ORDER BY created_at DESC", (user_id,))
    all_notifs = cur.fetchall()
    cur.execute("UPDATE notifications SET is_read = true WHERE user_id = %s", (user_id,))
    conn.commit()
    cur.close()
    conn.close()
    return render_template('notifications.html', notifications=all_notifs)

# app.py içindeki clubs fonksiyonunu bununla değiştir:
@app.route('/clubs')
def clubs():
    conn = get_db_connection()
    cur = conn.cursor()
    
    search_query = request.args.get('q', '')
    
    base_query = """
        SELECT c.club_id, c.club_name, c.description, c.club_image_url, u.username, COUNT(cm.user_id) 
        FROM clubs c 
        JOIN users u ON c.owner_id = u.user_id 
        LEFT JOIN club_members cm ON c.club_id = cm.club_id 
    """
    
    params = []
    if search_query:
        base_query += " WHERE c.club_name ILIKE %s"
        params.append(f"%{search_query}%")
        
    base_query += " GROUP BY c.club_id, c.club_name, c.description, c.club_image_url, u.username ORDER BY 6 DESC;"
    
    cur.execute(base_query, tuple(params))
    clubs_list = cur.fetchall()
    
    cur.close()
    conn.close()
    return render_template('clubs.html', clubs=clubs_list, search_query=search_query)

@app.route('/create_club', methods=['GET', 'POST'])
def create_club():
    if 'user_id' not in session: return redirect(url_for('login'))
    
    if request.method == 'POST':
        conn = get_db_connection()
        cur = conn.cursor()
        try:
            club_name = request.form['club_name']
            desc = request.form['description']
            img = request.form['image_url'] if request.form['image_url'] else 'https://loremflickr.com/500/300/hiking'
            owner_id = session['user_id']
            
            cur.execute("""
                INSERT INTO clubs (club_name, description, owner_id, club_image_url) 
                VALUES (%s, %s, %s, %s) RETURNING club_id
            """, (club_name, desc, owner_id, img))
            new_club_id = cur.fetchone()[0]
            
            cur.execute("INSERT INTO club_members (club_id, user_id, role) VALUES (%s, %s, 'admin')", (new_club_id, owner_id))
            conn.commit()
            flash("Kulüp kuruldu! Başkan sensin.", "success")
            return redirect(url_for('clubs'))
        except Exception as e:
            conn.rollback()
            flash(f"Hata: {e}", "danger")
        finally:
            cur.close()
            conn.close()
            
    return render_template('create_club.html')

# --- KULÜP DÜZENLEME (YENİ) ---
@app.route('/edit_club/<int:club_id>', methods=['GET', 'POST'])
def edit_club(club_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    # Kulübü bul
    cur.execute("SELECT * FROM clubs WHERE club_id = %s", (club_id,))
    club = cur.fetchone()
    
    # Yetki Kontrolü: Sadece kulübün sahibi (owner_id) değiştirebilir
    # club[3] = owner_id
    if not club or club[3] != session['user_id']:
        flash("Bu kulübü düzenleme yetkiniz yok.", "danger")
        cur.close()
        conn.close()
        return redirect(url_for('club_detail', club_id=club_id))
        
    if request.method == 'POST':
        new_name = request.form['club_name']
        new_desc = request.form['description']
        new_img = request.form['image_url']
        
        try:
            cur.execute("""
                UPDATE clubs 
                SET club_name = %s, description = %s, club_image_url = %s 
                WHERE club_id = %s
            """, (new_name, new_desc, new_img, club_id))
            conn.commit()
            flash("Kulüp bilgileri başarıyla güncellendi! ✅", "success")
            return redirect(url_for('club_detail', club_id=club_id))
        except Exception as e:
            conn.rollback()
            flash("Bir hata oluştu. Kulüp adı kullanımda olabilir.", "danger")
    
    cur.close()
    conn.close()
    return render_template('edit_club.html', club=club)

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

    # 1. Önce kulüp bilgilerini çek (Yetki kontrolü ve sayfa için gerekli)
    cur.execute("""
        SELECT c.*, u.username as owner_name 
        FROM clubs c 
        JOIN users u ON c.owner_id = u.user_id 
        WHERE c.club_id = %s
    """, (club_id,))
    club = cur.fetchone()

    if not club:
        cur.close()
        conn.close()
        return "Kulüp bulunamadı", 404

    # 2. POST İsteği Geldiyse (Duyuru Paylaşma)
    if request.method == 'POST' and 'user_id' in session:
        # --- GÜVENLİK KONTROLÜ ---
        if club[3] != session['user_id']: 
            flash("Sadece kulüp başkanı duyuru paylaşabilir! 🚫", "danger")
        else:
            try:
                message = request.form['message']
                sender_id = session['user_id']
                
                # Duyuruyu Veritabanına Yaz
                cur.execute("INSERT INTO club_announcements (club_id, sender_id, message) VALUES (%s, %s, %s)", 
                            (club_id, sender_id, message))
                
                # Üyelere Bildirim Gönder
                club_name = request.form['club_name'] 
                notif_msg = f"📢 {club_name}: {message[:20]}..."
                
                # Kendisi hariç diğer üyeleri bul
                cur.execute("SELECT user_id FROM club_members WHERE club_id = %s AND user_id != %s", (club_id, sender_id))
                members = cur.fetchall()
                
                for member in members:
                    cur.execute("INSERT INTO notifications (user_id, message) VALUES (%s, %s)", (member[0], notif_msg))
                
                conn.commit()
                flash("Duyuru başarıyla paylaşıldı! ✅", "success")
                
            except Exception as e:
                conn.rollback()
                flash(f"Bir hata oluştu: {e}", "danger")

    # 3. Üyelik Durumu Kontrolü (Görüntüleme için)
    is_member = False
    if 'user_id' in session:
        cur.execute("SELECT 1 FROM club_members WHERE club_id=%s AND user_id=%s", (club_id, session['user_id']))
        is_member = cur.fetchone() is not None

    # 4. Duyuruları ve Üye Listesini Çek (Sayfa içeriği için)
    cur.execute("""
        SELECT a.message, a.created_at, u.username, u.profile_picture_url 
        FROM club_announcements a 
        JOIN users u ON a.sender_id = u.user_id 
        WHERE a.club_id = %s 
        ORDER BY a.created_at DESC
    """, (club_id,))
    announcements = cur.fetchall()

    cur.execute("""
        SELECT u.user_id, u.username, u.profile_picture_url 
        FROM club_members cm 
        JOIN users u ON cm.user_id = u.user_id 
        WHERE cm.club_id = %s
    """, (club_id,))
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
    
    # 1. Arkadaş Arama Kısmı
    search_results = []
    if request.method == 'POST' and 'search_query' in request.form:
        query = request.form['search_query']
        cur.execute("SELECT user_id, username, profile_picture_url FROM users WHERE username ILIKE %s AND user_id != %s", (f'%{query}%', user_id))
        search_results = cur.fetchall()
    
    # 2. Bekleyen İstekler
    cur.execute("""SELECT f.friendship_id, u.username, u.profile_picture_url, u.user_id FROM friendships f JOIN users u ON f.requester_id = u.user_id WHERE f.addressee_id = %s AND f.status = 'pending'""", (user_id,))
    pending_requests = cur.fetchall()
    
    # 3. MEVCUT ARKADAŞLAR (Burayı DISTINCT ile güncelledik)
    cur.execute("""
        SELECT DISTINCT u.username, u.profile_picture_url, u.user_id 
        FROM friendships f 
        JOIN users u ON (f.requester_id = u.user_id OR f.addressee_id = u.user_id) 
        WHERE (f.requester_id = %s OR f.addressee_id = %s) 
          AND f.status = 'accepted' 
          AND u.user_id != %s
    """, (user_id, user_id, user_id))
    my_friends = cur.fetchall()
    
    cur.close()
    conn.close()
    return render_template('friends.html', search_results=search_results, pending_requests=pending_requests, my_friends=my_friends)


@app.route('/add_friend/<int:target_id>')
def add_friend(target_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    me = session['user_id']
    
    # 1. KONTROL: Zaten bir ilişki var mı? (Yön fark etmeksizin)
    cur.execute("""
        SELECT status, requester_id FROM friendships 
        WHERE (requester_id = %s AND addressee_id = %s) 
           OR (requester_id = %s AND addressee_id = %s)
    """, (me, target_id, target_id, me))
    
    existing = cur.fetchone()
    
    if existing:
        status, requester = existing
        if status == 'accepted':
            flash("Zaten arkadaşsınız!", "warning")
        elif status == 'pending':
            if requester == me:
                flash("İstek zaten gönderilmiş, cevap bekleniyor.", "info")
            else:
                flash("Bu kişi sana zaten istek atmış! İstekler kutuna bak.", "info")
    else:
        # 2. KAYIT: İlişki yoksa ekle
        try:
            cur.execute("INSERT INTO friendships (requester_id, addressee_id, status) VALUES (%s, %s, 'pending')", (me, target_id))
            
            # Bildirim gönder
            cur.execute("INSERT INTO notifications (user_id, message) VALUES (%s, %s)", 
                        (target_id, f"{session['username']} sana arkadaşlık isteği gönderdi."))
            
            conn.commit()
            flash("Arkadaşlık isteği gönderildi.", "success")
        except Exception as e:
            conn.rollback()
            print("Arkadaş Ekleme Hatası:", e)
            flash("Bir hata oluştu.", "danger")
            
    cur.close()
    conn.close()
    return redirect(url_for('friends'))

# --- ARKADAŞLIKTAN ÇIKARMA (YENİ) ---
@app.route('/remove_friend/<int:target_id>')
def remove_friend(target_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        me = session['user_id']
        
        # İlişkiyi veritabanından tamamen sil
        cur.execute("""
            DELETE FROM friendships 
            WHERE (requester_id = %s AND addressee_id = %s) 
               OR (requester_id = %s AND addressee_id = %s)
        """, (me, target_id, target_id, me))
        
        conn.commit()
        flash("Arkadaşlıktan çıkarıldı.", "info")
        
    except Exception as e:
        conn.rollback()
        print("Silme Hatası:", e)
        flash("Bir hata oluştu.", "danger")
        
    finally:
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
def route_detail_full(route_id):
    return route_detail(route_id)

@app.route('/route_detail/<int:route_id>', methods=['GET', 'POST'])
def route_detail(route_id):
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        if request.method == 'POST':
             if 'user_id' not in session: return redirect(url_for('login'))
             try:
                 cur.execute("INSERT INTO route_reviews (route_id, user_id, comment, rating) VALUES (%s, %s, %s, %s)", 
                             (route_id, session['user_id'], request.form['comment'], request.form['rating']))
                 conn.commit()
             except: conn.rollback()
        
        cur.execute("SELECT r.*, u.username, u.profile_picture_url FROM routes r JOIN users u ON r.creator_id = u.user_id WHERE r.route_id = %s", (route_id,))
        route = cur.fetchone()
        
        cur.execute("SELECT * FROM stops WHERE route_id = %s ORDER BY stop_order", (route_id,))
        stops = cur.fetchall()
        
        cur.execute("SELECT r.rating, r.comment, r.created_at, u.username, u.profile_picture_url, u.user_id FROM route_reviews r JOIN users u ON r.user_id = u.user_id WHERE r.route_id = %s ORDER BY r.created_at DESC", (route_id,))
        reviews = cur.fetchall()
        
        cur.close()
        conn.close()
        return render_template('route_detail.html', route=route, stops=stops, reviews=reviews)
    return "Hata"

@app.context_processor
def inject_notifications():
    notifications = []
    unread_count = 0
    if 'user_id' in session:
        conn = get_db_connection()
        if conn:
            cur = conn.cursor()
            user_id = session['user_id']
            # notification_id (4. sütun) eklendi
            cur.execute("SELECT message, created_at, is_read, notification_id FROM notifications WHERE user_id = %s ORDER BY created_at DESC LIMIT 5", (user_id,))
            notifications = cur.fetchall()
            cur.execute("SELECT COUNT(*) FROM notifications WHERE user_id = %s AND is_read = false", (user_id,))
            unread_count = cur.fetchone()[0]
            cur.close()
            conn.close()
    return dict(notifications=notifications, unread_count=unread_count)

# --- DÜZELTİLEN YER: SÜTUNLAR ELLE SIRALANDI ---
@app.route('/event/<int:event_id>')
def event_detail(event_id):
    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        
        # SQL Sorgusu artık e.* değil, HTML'in beklediği sıraya göre elle yazıldı.
        cur.execute("""
            SELECT 
                e.event_id,             -- [0]
                e.organizer_id,         -- [1]
                e.route_id,             -- [2]
                e.category_id,          -- [3]
                e.event_date,           -- [4]
                e.description,          -- [5] (Başlık ve Açıklama)
                e.status,               -- [6] (Badge Rengi)
                e.max_participants,     -- [7] (Kontenjan Hesabı)
                e.deadline,             -- [8] (Boş)
                r.distance_km,          -- [9]
                r.estimated_duration,   -- [10]
                u.username,             -- [11]
                u.profile_picture_url,  -- [12]
                c.category_name,        -- [13]
                (SELECT COUNT(*) FROM participations WHERE event_id = e.event_id) -- [14] (Sayı, int)
            FROM events e
            JOIN routes r ON e.route_id = r.route_id
            JOIN users u ON e.organizer_id = u.user_id
            JOIN categories c ON e.category_id = c.category_id
            WHERE e.event_id = %s
        """, (event_id,))
        event = cur.fetchone()
        
        if not event: return "Etkinlik bulunamadı", 404

        cur.execute("SELECT * FROM stops WHERE route_id = %s ORDER BY stop_order", (event[2],))
        stops = cur.fetchall()

        cur.execute("""
            SELECT u.user_id, u.username, u.profile_picture_url 
            FROM participations p 
            JOIN users u ON p.user_id = u.user_id 
            WHERE p.event_id = %s
        """, (event_id,))
        participants = cur.fetchall()
        
        am_i_joined = False
        if 'user_id' in session:
            am_i_joined = any(p[0] == session['user_id'] for p in participants)

        cur.close()
        conn.close()
        return render_template('event_detail.html', event=event, stops=stops, participants=participants, am_i_joined=am_i_joined)
    return "Hata"

# --- BİLDİRİM SİLME İŞLEMLERİ (YENİ) ---

@app.route('/delete_notification/<int:notif_id>')
def delete_notification(notif_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        # Sadece kendi bildirimini silebilir
        cur.execute("DELETE FROM notifications WHERE notification_id = %s AND user_id = %s", (notif_id, session['user_id']))
        conn.commit()
    except Exception as e:
        conn.rollback()
        print("Bildirim Silme Hatası:", e)
    finally:
        cur.close()
        conn.close()
    
    # İşlem bitince geldiği sayfaya geri dönsün (Navbar ise oraya, sayfa ise sayfaya)
    return redirect(request.referrer or url_for('index'))

@app.route('/delete_all_notifications')
def delete_all_notifications():
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        cur.execute("DELETE FROM notifications WHERE user_id = %s", (session['user_id'],))
        conn.commit()
        flash("Tüm bildirimler temizlendi.", "success")
    except:
        conn.rollback()
    finally:
        cur.close()
        conn.close()
        
    return redirect(url_for('notifications_page'))

# --- ROTA SİLME (YENİ) ---
@app.route('/delete_route/<int:route_id>')
def delete_route(route_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    # Rota kime ait kontrol et
    cur.execute("SELECT creator_id FROM routes WHERE route_id = %s", (route_id,))
    route = cur.fetchone()
    
    if route and route[0] == session['user_id']:
        try:
            # Önce bu rotaya bağlı durakları, yorumları ve etkinlikleri temizle (Eğer CASCADE yoksa)
            cur.execute("DELETE FROM stops WHERE route_id = %s", (route_id,))
            cur.execute("DELETE FROM route_reviews WHERE route_id = %s", (route_id,))
            # Etkinlik varsa, etkinliği iptal et veya sil (Burada siliyoruz)
            cur.execute("DELETE FROM events WHERE route_id = %s", (route_id,))
            
            # Son olarak rotayı sil
            cur.execute("DELETE FROM routes WHERE route_id = %s", (route_id,))
            conn.commit()
            flash("Rota başarıyla silindi.", "success")
        except Exception as e:
            conn.rollback()
            print("Rota Silme Hatası:", e)
            flash("Rota silinirken bir hata oluştu (Bağlı veriler olabilir).", "danger")
    else:
        flash("Bu işlem için yetkiniz yok.", "danger")
        
    cur.close()
    conn.close()
    return redirect(url_for('profile', user_id=session['user_id']))


if __name__ == '__main__':
    app.run(debug=True)