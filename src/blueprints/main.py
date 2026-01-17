import os
import json
from flask import Blueprint, render_template, request, redirect, url_for, session, flash, current_app
from werkzeug.utils import secure_filename
from db import get_db

# Blueprint Tanımı
main_bp = Blueprint('main', __name__)

# Yardımcı Fonksiyon: Dosya Uzantısı Kontrolü
def allowed_file(filename):
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ==========================================
# ANA SAYFALAR & PROFİL
# ==========================================

@main_bp.route('/')
def index():
    with get_db() as conn:
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
    
    return render_template('index.html', stats=stats, leaders=leaders, popular_routes=popular_routes)

@main_bp.route('/profile/<int:user_id>/')
def profile(user_id):
    with get_db() as conn:
        cur = conn.cursor()
        
        # --- [OTOMATİK KONTROL] ---
        if 'user_id' in session and session['user_id'] == user_id:
            try:
                cur.execute("""
                    UPDATE participations p
                    SET is_completed = TRUE
                    FROM events e
                    WHERE p.event_id = e.event_id 
                    AND e.deadline < NOW() 
                    AND p.is_completed = FALSE
                    AND p.user_id = %s
                """, (user_id,))
            except Exception as e:
                current_app.logger.error(f"Otomatik tamamlama hatası: {e}")

        # 1. Kullanıcı Bilgileri
        cur.execute("SELECT user_id, username, password, role, total_points, age, bio, profile_picture_url, created_at, gender FROM users WHERE user_id = %s", (user_id,))
        user = cur.fetchone()
        
        if not user: return "Kullanıcı bulunamadı!", 404

        # Seviye ve Renk Hesaplama
        user_level = "Belirsiz"
        user_rank_color = "bg-gray-100 text-gray-600 border-gray-200" 
        try:
            cur.execute("SELECT calculate_user_level(%s)", (user[4],))
            user_level_from_func = cur.fetchone()[0]
            user_level = user_level_from_func

            cur.execute("SELECT color_class FROM ranks WHERE name = %s", (user_level,))
            color_res = cur.fetchone()
            if color_res:
                user_rank_color = color_res[0]
        except Exception as e: 
            current_app.logger.error(f"Seviye Hesaplama Hatası: {e}")

        # 2. Rozetler
        cur.execute("SELECT b.badge_name, b.icon_url, b.description FROM user_badges ub JOIN badges b ON ub.badge_id = b.badge_id WHERE ub.user_id = %s", (user_id,))
        badges = cur.fetchall()

        # Hobiler
        cur.execute("SELECT h.hobby_name, h.icon FROM user_hobbies uh JOIN hobbies h ON uh.hobby_id = h.hobby_id WHERE uh.user_id = %s", (user_id,))
        hobbies = cur.fetchall()

        cur.execute("SELECT u.user_id, u.username, u.profile_picture_url FROM friendships f JOIN users u ON (f.requester_id = u.user_id OR f.addressee_id = u.user_id) WHERE (f.requester_id = %s OR f.addressee_id = %s) AND f.status = 'accepted' AND u.user_id != %s", (user_id, user_id, user_id))
        friends = cur.fetchall()

        # 3. Rotalar
        cur.execute("SELECT route_id, route_name, distance_km, difficulty_level FROM routes WHERE creator_id = %s ORDER BY route_id DESC", (user_id,))
        created_routes = cur.fetchall()

        # 4. Etkinlik Listeleri
        cur.execute("""
            SELECT e.event_id, r.route_name, e.event_date, e.deadline, e.title
            FROM participations p
            JOIN events e ON p.event_id = e.event_id
            JOIN routes r ON e.route_id = r.route_id
            WHERE p.user_id = %s AND e.deadline >= NOW()
            ORDER BY e.event_date ASC
        """, (user_id,))
        upcoming_events = cur.fetchall()

        cur.execute("""
            SELECT e.event_id, r.route_name, e.event_date, r.distance_km, e.title
            FROM participations p
            JOIN events e ON p.event_id = e.event_id
            JOIN routes r ON e.route_id = r.route_id
            WHERE p.user_id = %s AND e.deadline < NOW()
            ORDER BY e.event_date DESC
        """, (user_id,))
        past_events = cur.fetchall()

        cur.execute("""
            SELECT e.event_id, r.route_name, e.event_date, e.status, 
                   (SELECT COUNT(*) FROM participations WHERE event_id = e.event_id) as part_count,
                   e.title
            FROM events e
            JOIN routes r ON e.route_id = r.route_id
            WHERE e.organizer_id = %s
            ORDER BY e.event_date DESC
        """, (user_id,))
        organized_events = cur.fetchall()

        # 5. [DÜZELTİLDİ] Üye Olunan Kulüpler
        # club_image_url ve owner_id düzeltildi.
        cur.execute("""
            SELECT 
                c.club_id, 
                c.club_name, 
                c.club_image_url, 
                (SELECT COUNT(*) FROM club_members cm2 WHERE cm2.club_id = c.club_id) as member_count,
                CASE WHEN c.owner_id = %s THEN 'admin' ELSE 'member' END as role
            FROM clubs c
            JOIN club_members cm ON c.club_id = cm.club_id
            WHERE cm.user_id = %s
        """, (user_id, user_id))
        clubs = cur.fetchall()
        
    return render_template('profile.html', user=user, badges=badges, hobbies=hobbies, 
                          friends=friends, created_routes=created_routes, 
                          user_level=user_level, user_rank_color=user_rank_color,
                          upcoming_events=upcoming_events, past_events=past_events, 
                          organized_events=organized_events, clubs=clubs)

@main_bp.route('/edit_profile', methods=['GET', 'POST'])
def edit_profile():
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    user_id = session['user_id']
    
    with get_db() as conn:
        cur = conn.cursor()

        if request.method == 'POST':
            bio = request.form['bio']
            age = request.form['age'] if request.form['age'] else None
            selected_hobbies = request.form.getlist('hobbies')
            
            if 'profile_pic' in request.files:
                file = request.files['profile_pic']
                if file and allowed_file(file.filename):
                    filename = secure_filename(f"user_{user_id}_{file.filename}")
                    # current_app ile config'e erişiyoruz
                    file.save(os.path.join(current_app.config['UPLOAD_FOLDER'], filename))
                    new_url = f"/static/uploads/{filename}"
                    cur.execute("UPDATE users SET profile_picture_url = %s WHERE user_id = %s", (new_url, user_id))

            cur.execute("UPDATE users SET bio = %s, age = %s WHERE user_id = %s", (bio, age, user_id))
            
            cur.execute("DELETE FROM user_hobbies WHERE user_id = %s", (user_id,))
            for hobby_id in selected_hobbies:
                cur.execute("INSERT INTO user_hobbies (user_id, hobby_id) VALUES (%s, %s)", (user_id, hobby_id))
                
            conn.commit()
            flash("Profiliniz güncellendi!", "success")
            return redirect(url_for('main.profile', user_id=user_id))

        cur.execute("""
            SELECT user_id, username, password, role, total_points, age, bio, profile_picture_url 
            FROM users WHERE user_id = %s
        """, (user_id,))
        user = cur.fetchone()
        
        cur.execute("SELECT * FROM hobbies")
        all_hobbies = cur.fetchall()
        
        cur.execute("SELECT hobby_id FROM user_hobbies WHERE user_id = %s", (user_id,))
        my_hobby_ids = [row[0] for row in cur.fetchall()]

    return render_template('edit_profile.html', user=user, hobbies=all_hobbies, my_hobby_ids=my_hobby_ids)

@main_bp.route('/leaderboard/')
def leaderboard():
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM view_leaderboard;")
        leaders = cur.fetchall()
    return render_template('leaderboard.html', leaders=leaders)

# ==========================================
# ROTALAR (ROUTES)
# ==========================================

@main_bp.route('/routes/')
def routes():
    with get_db() as conn:
        cur = conn.cursor()
        
        # Filtre Parametrelerini Al
        search_query = request.args.get('q', '')
        min_dist = request.args.get('min_dist')
        max_dist = request.args.get('max_dist')
        difficulty = request.args.get('difficulty')
        
        # Dinamik Sorgu Oluşturma (View üzerinden)
        # view_popular_routes zaten rotaları listeliyor, üzerine filtre ekleyeceğiz.
        sql = "SELECT * FROM view_popular_routes WHERE 1=1"
        params = []
        
        # 1. İsim Araması
        if search_query:
            sql += " AND route_name ILIKE %s"
            params.append(f"%{search_query}%")
        
        # 2. Mesafe Filtresi (SQL Fonksiyonu Kullanımı: search_routes_by_distance)
        if min_dist or max_dist:
            # Fonksiyon kullanımı zorunluluğu için mesafe filtresini fonksiyon üzerinden yapıyoruz
            low = float(min_dist) if min_dist else 0
            high = float(max_dist) if max_dist else 100000
            
            # Fonksiyondan dönen ID'leri alıp ana sorguya ekliyoruz
            # "Arayüzden girilen değerleri parametre olarak alıp..." kuralı için.
            sql += f" AND route_id IN (SELECT r_id FROM search_routes_by_distance({low}, {high}))"
            
        # 3. Zorluk Filtresi
        if difficulty:
            sql += " AND difficulty_level = %s"
            params.append(difficulty)
            
        # Sıralama
        sql += " ORDER BY event_count DESC, average_rating DESC"
        
        cur.execute(sql, tuple(params))
        routes_list = cur.fetchall()
        
        # Harita Verisi (Duraklar)
        cur.execute("SELECT route_id, location_name, latitude, longitude FROM stops ORDER BY route_id, stop_order;")
        stops = cur.fetchall()
        map_data = {}
        for stop in stops:
            r_id = str(stop[0]) 
            lat = float(stop[2]) if stop[2] else 0
            lon = float(stop[3]) if stop[3] else 0
            if r_id not in map_data: map_data[r_id] = []
            map_data[r_id].append([lat, lon])
            
    return render_template('routes.html', routes=routes_list, map_data=json.dumps(map_data))

@main_bp.route('/route/<int:route_id>', methods=['GET', 'POST'])
def route_detail_full(route_id):
    return route_detail(route_id)

@main_bp.route('/route_detail/<int:route_id>/', methods=['GET', 'POST'])
def route_detail(route_id):
    with get_db() as conn:
        cur = conn.cursor()
        
        # --- [POST] Yorum Ekleme ---
        if request.method == 'POST':
             if 'user_id' not in session: return redirect(url_for('auth.login'))
             try:
                 cur.execute("INSERT INTO route_reviews (route_id, user_id, comment, rating) VALUES (%s, %s, %s, %s)", 
                             (route_id, session['user_id'], request.form['comment'], request.form['rating']))
                 conn.commit()
                 flash("Yorumunuz başarıyla eklendi! 🌟", "success")
             except Exception as e: 
                 flash(f"Yorum eklenirken hata oluştu: {e}", "danger")
        
        # --- [GET] Rota Detayları (Ortalama Puanlı) ---
        # Tasarımdaki indeks sırasına göre özel SELECT yazdık:
        # 0:id, 1:creator_id, 2:name, 3:dist, 4:diff, 5:dur, 6:date, 7:username, 8:RATING(AVG), 9:pp
        cur.execute("""
            SELECT 
                r.route_id, 
                r.creator_id, 
                r.route_name, 
                r.distance_km, 
                r.difficulty_level, 
                r.estimated_duration, 
                r.created_at,
                u.username,
                COALESCE(AVG(rr.rating), 0) as avg_rating,
                u.profile_picture_url
            FROM routes r 
            JOIN users u ON r.creator_id = u.user_id 
            LEFT JOIN route_reviews rr ON r.route_id = rr.route_id
            WHERE r.route_id = %s
            GROUP BY r.route_id, u.user_id, u.username, u.profile_picture_url
        """, (route_id,))
        route = cur.fetchone()
        
        if not route: return "Rota bulunamadı", 404
        
        # --- [GET] Duraklar (Cursor Fonksiyonu) ---
        cur.execute("SELECT * FROM get_stops_via_cursor(%s)", (route_id,))
        stops = cur.fetchall()
        
        # --- [GET] Yorumlar ---
        cur.execute("""
            SELECT r.rating, r.comment, r.created_at, u.username, u.profile_picture_url, u.user_id 
            FROM route_reviews r 
            JOIN users u ON r.user_id = u.user_id 
            WHERE r.route_id = %s 
            ORDER BY r.created_at DESC
        """, (route_id,))
        reviews = cur.fetchall()
        
    return render_template('route_detail.html', route=route, stops=stops, reviews=reviews)
@main_bp.route('/delete_route/<int:route_id>')
def delete_route(route_id):
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    with get_db() as conn:
        cur = conn.cursor()
        
        cur.execute("SELECT creator_id FROM routes WHERE route_id = %s", (route_id,))
        route = cur.fetchone()
        
        if route and route[0] == session['user_id']:
            try:
                cur.execute("DELETE FROM stops WHERE route_id = %s", (route_id,))
                cur.execute("DELETE FROM route_reviews WHERE route_id = %s", (route_id,))
                cur.execute("DELETE FROM events WHERE route_id = %s", (route_id,))
                cur.execute("DELETE FROM routes WHERE route_id = %s", (route_id,))
                conn.commit()
                flash("Rota başarıyla silindi.", "success")
            except Exception as e:
                current_app.logger.error(f"Rota Silme Hatası: {e}")
                flash("Rota silinirken bir hata oluştu.", "danger")
        else:
            flash("Bu işlem için yetkiniz yok.", "danger")
        
    return redirect(url_for('main.profile', user_id=session['user_id']))

# ==========================================
# ETKİNLİKLER (EVENTS)
# ==========================================

@main_bp.route('/events/', methods=['GET'])
def events():
    with get_db() as conn:
        cur = conn.cursor()
        
        # 1. Tarihi geçenleri otomatik 'completed' yap (Statusu 'cancelled' olanlara dokunma, onlar zaten bitmiş)
        cur.execute("""
            UPDATE events 
            SET status = 'completed' 
            WHERE event_date < NOW() AND status IN ('active', 'upcoming')
        """)
        conn.commit()

        # Filtreleri Al
        search_query = request.args.get('q', '')
        category_filter = request.args.get('category')
        time_filter = request.args.get('time', 'upcoming') # Varsayılan: Yaklaşan (upcoming)

        # Temel Sorgu
        base_query = """
            SELECT e.event_id, e.event_date, e.status, e.description, e.max_participants,
                   r.route_name, r.distance_km, u.username, c.category_name, c.icon_url,
                   (SELECT COUNT(*) FROM participations WHERE event_id = e.event_id) as current_count,
                   e.organizer_id, e.title, u.profile_picture_url
            FROM events e
            JOIN routes r ON e.route_id = r.route_id
            JOIN users u ON e.organizer_id = u.user_id
            JOIN categories c ON e.category_id = c.category_id
            WHERE 1=1 
        """
        params = []

        # Zaman Filtresi Mantığı
        if time_filter == 'past':
            # Geçmiş: Tarihi eskide kalmış VEYA statusu completed olanlar
            base_query += " AND (e.event_date < NOW() OR e.status = 'completed')"
        else:
            # Güncel (Varsayılan): Tarihi gelmemiş VE completed olmayanlar (Cancelled dahil görünür)
            base_query += " AND e.event_date >= NOW() AND e.status != 'completed'"

        # Arama Filtresi
        if search_query:
            base_query += " AND (e.title ILIKE %s OR e.description ILIKE %s OR r.route_name ILIKE %s)"
            term = f"%{search_query}%"
            params.extend([term, term, term])
        
        # Kategori Filtresi
        if category_filter:
            base_query += " AND c.category_name = %s"
            params.append(category_filter)
        
        # Sıralama: Yaklaşanlar için en yakın tarih, Geçmişler için en son tarih
        if time_filter == 'past':
            base_query += " ORDER BY e.event_date DESC"
        else:
            base_query += " ORDER BY e.event_date ASC"

        cur.execute(base_query, tuple(params))
        events_list = cur.fetchall()
        
        cur.execute("SELECT category_name FROM categories;")
        categories = cur.fetchall()

        my_participations = []
        if 'user_id' in session:
            cur.execute("SELECT event_id FROM participations WHERE user_id = %s", (session['user_id'],))
            my_participations = [row[0] for row in cur.fetchall()]
        
    return render_template('events.html', events=events_list, categories=categories, my_events=my_participations, search_query=search_query, current_time_filter=time_filter)


@main_bp.route('/event/<int:event_id>/')
def event_detail(event_id):
    with get_db() as conn:
        cur = conn.cursor()
        
        # [GÜNCELLENDİ] r.route_name (16) ve r.route_id (17) eklendi
        cur.execute("""
            SELECT e.event_id, e.organizer_id, e.route_id, e.category_id, e.event_date, e.description,
                   e.status, e.max_participants, e.deadline, r.distance_km, r.estimated_duration,
                   u.username, u.profile_picture_url, c.category_name,
                   (SELECT COUNT(*) FROM participations WHERE event_id = e.event_id),
                   e.title,
                   r.route_name,  -- Index 16
                   r.route_id     -- Index 17
            FROM events e
            JOIN routes r ON e.route_id = r.route_id
            JOIN users u ON e.organizer_id = u.user_id
            JOIN categories c ON e.category_id = c.category_id
            WHERE e.event_id = %s
        """, (event_id,))
        event = cur.fetchone()
        
        if not event: return "Etkinlik Bulunamadı", 404
        
        # Stops sorgusuna location_name (durak ismi) de geliyor (Index 2)
        cur.execute("SELECT * FROM stops WHERE route_id = %s ORDER BY stop_order", (event[2],))
        stops = cur.fetchall()
        
        cur.execute("SELECT u.user_id, u.username, u.profile_picture_url FROM participations p JOIN users u ON p.user_id = u.user_id WHERE p.event_id = %s", (event_id,))
        participants = cur.fetchall()
        
        am_i_joined = False
        if 'user_id' in session:
            am_i_joined = any(p[0] == session['user_id'] for p in participants)
            
    return render_template('event_detail.html', event=event, stops=stops, participants=participants, am_i_joined=am_i_joined)

@main_bp.route('/join_event/<int:event_id>')
def join_event(event_id):
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    with get_db() as conn:
        cur = conn.cursor()
        try:
            cur.execute("SELECT count(*) FROM participations WHERE event_id = %s", (event_id,))
            current_count = cur.fetchone()[0]
            cur.execute("SELECT max_participants FROM events WHERE event_id = %s", (event_id,))
            max_limit = cur.fetchone()[0]
            
            if current_count >= max_limit:
                flash("Malesef kontenjan dolu.", "warning")
            else:
                cur.execute("INSERT INTO participations (user_id, event_id) VALUES (%s, %s)", (session['user_id'], event_id))
                conn.commit()
                flash("Etkinliğe başarıyla kaydoldun! 🏃‍♂️", "success")
        except Exception as e:
            current_app.logger.error(f"KATILMA HATASI: {e}")
            flash("Zaten bu etkinliğe katılıyorsunuz.", "info")
            
    return redirect(url_for('main.events'))

@main_bp.route('/cancel_event/<int:event_id>')
def cancel_event(event_id):
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    with get_db() as conn:
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
                    cur.execute("INSERT INTO notifications (user_id, message, related_link) VALUES (%s, %s, %s)", 
                                (p[0], notif_msg, "/events"))
            
            conn.commit()
            flash("Etkinlik iptal edildi ve katılımcılara bildirim gönderildi.", "info")
        else:
            flash("Bu işlem için yetkiniz yok.", "danger")
        
    return redirect(url_for('main.events'))

@main_bp.route('/create', methods=['GET', 'POST'])
def create():
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    with get_db() as conn:
        cur = conn.cursor()

        if request.method == 'POST':
            form_type = request.form.get('form_type')

            # 1. ETKİNLİK OLUŞTURMA
            if form_type == 'event':
                title = request.form['title']
                description = request.form['description']
                event_date = request.form['event_date']
                deadline = request.form.get('deadline') or event_date
                max_participants = request.form['max_participants']
                category_id = request.form['category_id']
                route_mode = request.form.get('route_selection_mode')
                
                try:
                    final_route_id = None
                    if route_mode == 'new':
                        r_name = request.form['new_route_name']
                        r_dist = request.form['distance']
                        r_diff = request.form['difficulty']
                        r_dur = request.form['duration']
                        stops_json = request.form['stops_json']
                        
                        cur.execute("""
                            INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration)
                            VALUES (%s, %s, %s, %s, %s) RETURNING route_id
                        """, (session['user_id'], r_name, r_dist, r_diff, r_dur))
                        final_route_id = cur.fetchone()[0]
                        
                        if stops_json:
                            stops = json.loads(stops_json)
                            for idx, s in enumerate(stops):
                                # [GÜNCELLENDİ] İsim kontrolü eklendi
                                stop_name = s.get('name', f"Durak {idx+1}")
                                cur.execute("""
                                    INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude)
                                    VALUES (%s, %s, %s, %s, %s)
                                """, (final_route_id, idx+1, stop_name, s['lat'], s['lng']))
                    else:
                        final_route_id = request.form['route_id']

                    cur.execute("""
                        INSERT INTO events (title, description, event_date, deadline, max_participants, route_id, category_id, organizer_id, status)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'active')
                    """, (title, description, event_date, deadline, max_participants, final_route_id, category_id, session['user_id']))
                    
                    conn.commit()
                    flash("Etkinlik başarıyla oluşturuldu!", "success")
                    return redirect(url_for('main.events'))
                except Exception as e:
                    current_app.logger.error(f"Hata Mesajı: {e}")
                    flash(f"Oluşturulurken hata: {e}", "danger")

            # 2. SADECE ROTA OLUŞTURMA
            elif form_type == 'route_only':
                try:
                    r_name = request.form['route_name']
                    r_dist = request.form['distance']
                    r_diff = request.form['difficulty']
                    r_dur = request.form['duration']
                    stops_json = request.form['stops_json']
                    
                    cur.execute("""
                        INSERT INTO routes (creator_id, route_name, distance_km, difficulty_level, estimated_duration)
                        VALUES (%s, %s, %s, %s, %s) RETURNING route_id
                    """, (session['user_id'], r_name, r_dist, r_diff, r_dur))
                    new_route_id = cur.fetchone()[0]
                    
                    if stops_json:
                        stops = json.loads(stops_json)
                        for idx, s in enumerate(stops):
                            # [GÜNCELLENDİ] İsim kontrolü eklendi
                            stop_name = s.get('name', f"Durak {idx+1}")
                            cur.execute("""
                                INSERT INTO stops (route_id, stop_order, location_name, latitude, longitude)
                                VALUES (%s, %s, %s, %s, %s)
                            """, (new_route_id, idx+1, stop_name, s['lat'], s['lng']))
                    
                    conn.commit()
                    flash("Rota kütüphaneye eklendi! 🗺️", "success")
                    return redirect(url_for('main.routes'))
                except Exception as e:
                    current_app.logger.error(f"Rota Hatası: {e}")
                    flash("Rota kaydedilemedi.", "danger")

        # GET İsteği
        cur.execute("""
            SELECT route_id, route_name, distance_km, difficulty_level, average_rating 
            FROM view_popular_routes 
            ORDER BY route_name ASC
        """)
        routes = cur.fetchall()
        cur.execute("SELECT category_id, category_name FROM categories")
        categories = cur.fetchall()
        
    return render_template('create.html', routes=routes, categories=categories)

# ==========================================
# KULÜPLER (CLUBS)
# ==========================================

@main_bp.route('/clubs/')
def clubs():
    with get_db() as conn:
        cur = conn.cursor()
        search_query = request.args.get('q', '')
        
        if search_query:
            cur.execute("""
                SELECT c.club_id, c.club_name, c.description, c.club_image_url, u.username, COUNT(cm.user_id) as member_count
                FROM clubs c JOIN users u ON c.owner_id = u.user_id LEFT JOIN club_members cm ON c.club_id = cm.club_id 
                WHERE c.club_name ILIKE %s
                GROUP BY c.club_id, c.club_name, c.description, c.club_image_url, u.username
                ORDER BY member_count DESC
            """, (f"%{search_query}%",))
        else:
            cur.execute("SELECT * FROM view_popular_clubs")
        
        clubs_list = cur.fetchall()
    return render_template('clubs.html', clubs=clubs_list, search_query=search_query)

@main_bp.route('/create_club', methods=['GET', 'POST'])
def create_club():
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    if request.method == 'POST':
        with get_db() as conn:
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
                return redirect(url_for('main.clubs'))
            except Exception as e:
                flash(f"Hata: {e}", "danger")
            
    return render_template('create_club.html')

@main_bp.route('/club/<int:club_id>', methods=['GET', 'POST'])
def club_detail(club_id):
    with get_db() as conn:
        cur = conn.cursor()

        cur.execute("""
            SELECT c.*, u.username as owner_name FROM clubs c 
            JOIN users u ON c.owner_id = u.user_id WHERE c.club_id = %s
        """, (club_id,))
        club = cur.fetchone()

        if not club: return "Kulüp bulunamadı", 404

        if request.method == 'POST' and 'user_id' in session:
            if club[3] != session['user_id']: 
                flash("Sadece kulüp başkanı duyuru paylaşabilir! 🚫", "danger")
            else:
                try:
                    message = request.form['message']
                    sender_id = session['user_id']
                    cur.execute("INSERT INTO club_announcements (club_id, sender_id, message) VALUES (%s, %s, %s)", 
                                (club_id, sender_id, message))
                    
                    club_name = request.form['club_name'] 
                    notif_msg = f"📢 {club_name}: {message[:20]}..."
                    cur.execute("SELECT user_id FROM club_members WHERE club_id = %s AND user_id != %s", (club_id, sender_id))
                    members = cur.fetchall()
                    for member in members:
                        cur.execute("INSERT INTO notifications (user_id, message, related_link) VALUES (%s, %s, %s)", 
                                    (member[0], notif_msg, f"/club/{club_id}"))
                    conn.commit()
                    flash("Duyuru başarıyla paylaşıldı! ✅", "success")
                except Exception as e:
                    flash(f"Bir hata oluştu: {e}", "danger")

        is_member = False
        if 'user_id' in session:
            cur.execute("SELECT 1 FROM club_members WHERE club_id=%s AND user_id=%s", (club_id, session['user_id']))
            is_member = cur.fetchone() is not None

        cur.execute("""
            SELECT a.message, a.created_at, u.username, u.profile_picture_url FROM club_announcements a 
            JOIN users u ON a.sender_id = u.user_id WHERE a.club_id = %s ORDER BY a.created_at DESC
        """, (club_id,))
        announcements = cur.fetchall()

        cur.execute("""
            SELECT u.user_id, u.username, u.profile_picture_url FROM club_members cm 
            JOIN users u ON cm.user_id = u.user_id WHERE cm.club_id = %s
        """, (club_id,))
        members = cur.fetchall()
    
    return render_template('club_detail.html', club=club, announcements=announcements, members=members, is_member=is_member)

@main_bp.route('/join_club/<int:club_id>')
def join_club(club_id):
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    with get_db() as conn:
        cur = conn.cursor()
        try:
            cur.execute("INSERT INTO club_members (club_id, user_id) VALUES (%s, %s)", (club_id, session['user_id']))
            conn.commit()
            flash("Kulübe başarıyla katıldın!", "success")
        except:
            flash("Zaten bu kulübe üyesiniz.", "warning")
            
    return redirect(url_for('main.club_detail', club_id=club_id))

@main_bp.route('/edit_club/<int:club_id>', methods=['GET', 'POST'])
def edit_club(club_id):
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    with get_db() as conn:
        cur = conn.cursor()
        
        cur.execute("SELECT * FROM clubs WHERE club_id = %s", (club_id,))
        club = cur.fetchone()
        
        if not club or club[3] != session['user_id']:
            flash("Bu kulübü düzenleme yetkiniz yok.", "danger")
            return redirect(url_for('main.club_detail', club_id=club_id))
            
        if request.method == 'POST':
            new_name = request.form['club_name']
            new_desc = request.form['description']
            new_img = request.form['image_url']
            
            try:
                cur.execute("""
                    UPDATE clubs SET club_name = %s, description = %s, club_image_url = %s WHERE club_id = %s
                """, (new_name, new_desc, new_img, club_id))
                conn.commit()
                flash("Kulüp bilgileri başarıyla güncellendi! ✅", "success")
                return redirect(url_for('main.club_detail', club_id=club_id))
            except Exception as e:
                flash("Bir hata oluştu.", "danger")
    
    return render_template('edit_club.html', club=club)

# ==========================================
# ARKADAŞLAR (FRIENDS)
# ==========================================

@main_bp.route('/friends/', methods=['GET', 'POST'])
def friends():
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    user_id = session['user_id']
    
    with get_db() as conn:
        cur = conn.cursor()
        
        search_results = []
        if request.method == 'POST' and 'search_query' in request.form:
            query = request.form['search_query']
            cur.execute("SELECT user_id, username, profile_picture_url FROM users WHERE username ILIKE %s AND user_id != %s", (f'%{query}%', user_id))
            search_results = cur.fetchall()
            
        cur.execute("SELECT f.friendship_id, u.username, u.profile_picture_url, u.user_id FROM friendships f JOIN users u ON f.requester_id = u.user_id WHERE f.addressee_id = %s AND f.status = 'pending'", (user_id,))
        pending_requests = cur.fetchall()
        
        cur.execute("""
            SELECT DISTINCT u.username, u.profile_picture_url, u.user_id 
            FROM friendships f JOIN users u ON (f.requester_id = u.user_id OR f.addressee_id = u.user_id) 
            WHERE (f.requester_id = %s OR f.addressee_id = %s) AND f.status = 'accepted' AND u.user_id != %s
        """, (user_id, user_id, user_id))
        my_friends = cur.fetchall()

        cur.execute("""
            SELECT u.user_id, u.username, u.profile_picture_url FROM view_potential_friends_base v
            JOIN users u ON v.user_id = u.user_id WHERE u.user_id != %s LIMIT 4
        """, (user_id,))
        suggestions = cur.fetchall()

    return render_template('friends.html', search_results=search_results, pending_requests=pending_requests, my_friends=my_friends, suggestions=suggestions)

@main_bp.route('/add_friend/<int:target_id>')
def add_friend(target_id):
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    me = session['user_id']
    
    with get_db() as conn:
        cur = conn.cursor()

        cur.execute("""
            SELECT status, requester_id FROM friendships 
            WHERE (requester_id = %s AND addressee_id = %s) OR (requester_id = %s AND addressee_id = %s)
        """, (me, target_id, target_id, me))
        existing = cur.fetchone()
        
        if existing:
            status, requester = existing
            if status == 'accepted': flash("Zaten arkadaşsınız!", "warning")
            elif status == 'pending': flash("İstek zaten gönderilmiş veya alınmış.", "info")
        else:
            try:
                cur.execute("INSERT INTO friendships (requester_id, addressee_id, status) VALUES (%s, %s, 'pending')", (me, target_id))
                cur.execute("INSERT INTO notifications (user_id, message, related_link) VALUES (%s, %s, %s)", 
                            (target_id, f"{session['username']} sana arkadaşlık isteği gönderdi.", "/friends"))
                conn.commit()
                flash("Arkadaşlık isteği gönderildi.", "success")
            except Exception as e:
                current_app.logger.error(f"Arkadaş Ekleme Hatası: {e}")
                flash("Bir hata oluştu.", "danger")
            
    return redirect(url_for('main.friends'))

@main_bp.route('/accept_friend/<int:friendship_id>')
def accept_friend(friendship_id):
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("UPDATE friendships SET status = 'accepted' WHERE friendship_id = %s", (friendship_id,))
        cur.execute("SELECT requester_id FROM friendships WHERE friendship_id = %s", (friendship_id,))
        requester_id = cur.fetchone()[0]
        my_id = session['user_id']
        cur.execute("INSERT INTO notifications (user_id, message, related_link) VALUES (%s, %s, %s)", 
            (requester_id, f"{session['username']} arkadaşlık isteğini kabul etti! 🎉", f"/profile/{my_id}"))
        conn.commit()
    flash("Artık arkadaşsınız!", "success")
    return redirect(url_for('main.friends'))

@main_bp.route('/remove_friend/<int:target_id>')
def remove_friend(target_id):
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    me = session['user_id']
    
    with get_db() as conn:
        cur = conn.cursor()
        try:
            cur.execute("""
                DELETE FROM friendships 
                WHERE (requester_id = %s AND addressee_id = %s) OR (requester_id = %s AND addressee_id = %s)
            """, (me, target_id, target_id, me))
            conn.commit()
            flash("Arkadaşlıktan çıkarıldı.", "info")
        except:
            flash("Bir hata oluştu.", "danger")
        
    return redirect(url_for('main.friends'))

# Reddetme Rotası
@main_bp.route('/reject_friend/<int:request_id>')
def reject_friend(request_id):
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    with get_db() as conn:
        cur = conn.cursor()
        # İsteği silmek yerine durumunu 'rejected' yapıyoruz
        cur.execute("UPDATE friendships SET status = 'rejected' WHERE friendship_id = %s AND addressee_id = %s", (request_id, session['user_id']))
        conn.commit()
        flash("Arkadaşlık isteği reddedildi.", "info")
    
    return redirect(url_for('main.friends'))


# ==========================================
# BİLDİRİMLER (NOTIFICATIONS)
# ==========================================

# 1. BİLDİRİM SAYFASI ROTASI (Link verisi eklendi)
@main_bp.route('/notifications')
def notifications_page():
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    user_id = session['user_id']
    
    with get_db() as conn:
        cur = conn.cursor()
        # [GÜNCELLENDİ] related_link (Index 4) sorguya eklendi
        cur.execute("SELECT message, created_at, is_read, notification_id, related_link FROM notifications WHERE user_id = %s ORDER BY created_at DESC", (user_id,))
        all_notifs = cur.fetchall()
        
    return render_template('notifications.html', notifications=all_notifs)

# [YENİ] Manuel olarak tümünü okundu işaretleme rotası
@main_bp.route('/mark_all_read')
def mark_all_read():
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("UPDATE notifications SET is_read = true WHERE user_id = %s", (session['user_id'],))
        conn.commit()
        flash("Tüm bildirimler okundu olarak işaretlendi.", "success")
    
    return redirect(url_for('main.notifications_page'))

@main_bp.route('/delete_notification/<int:notif_id>')
def delete_notification(notif_id):
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("DELETE FROM notifications WHERE notification_id = %s AND user_id = %s", (notif_id, session['user_id']))
        conn.commit()
    
    return redirect(request.referrer or url_for('main.index'))

@main_bp.route('/delete_all_notifications')
def delete_all_notifications():
    if 'user_id' not in session: return redirect(url_for('auth.login'))
    
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("DELETE FROM notifications WHERE user_id = %s", (session['user_id'],))
        conn.commit()
        flash("Tüm bildirimler silindi.", "success")
        
    return redirect(url_for('main.notifications_page'))

# Context Processor (Blueprint'e özgü)
# 2. CONTEXT PROCESSOR (Hata ayıklama için güncellendi)
@main_bp.app_context_processor
def inject_notifications():
    notifications = []
    unread_count = 0
    if 'user_id' in session:
        # Try-Except bloğunu kaldırdık ki hatayı görebilelim.
        # Eğer sayfa açılmazsa terminaldeki hatayı bana söyleyin.
        with get_db() as conn:
            cur = conn.cursor()
            user_id = session['user_id']
            
            # Bildirimleri çek
            cur.execute("""
                SELECT message, created_at, is_read, notification_id, related_link 
                FROM notifications 
                WHERE user_id = %s 
                ORDER BY created_at DESC LIMIT 10
            """, (user_id,))
            notifications = cur.fetchall()
            
            # Okunmamış sayısı
            cur.execute("SELECT COUNT(*) FROM notifications WHERE user_id = %s AND is_read = false", (user_id,))
            unread_count = cur.fetchone()[0]

    return dict(notifications=notifications, unread_count=unread_count)

@main_bp.route('/debug/cursor/<int:route_id>')
def debug_cursor_function(route_id):
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM get_stops_via_cursor(%s)", (route_id,))
        result = cur.fetchall()
    return f"Cursor Fonksiyonu Çıktısı (Duraklar): {result}"