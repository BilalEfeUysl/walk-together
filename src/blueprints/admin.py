from flask import Blueprint, render_template, request, redirect, url_for, session, flash, current_app
from functools import wraps
from db import get_db

# Blueprint Tanımı
# url_prefix='/admin' sayesinde bu dosyadaki tüm linklerin başına otomatik '/admin' gelecek.
admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

# ----------------------------------------------------
# YARDIMCI FONKSİYONLAR (DECORATORS)
# ----------------------------------------------------
def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Admin değilse anasayfaya at
        if 'user_id' not in session or session.get('role') != 'admin':
            flash("Bu sayfaya erişim yetkiniz yok!", "danger")
            # 'main.index' -> main blueprint'i oluşturunca çalışacak
            # Şimdilik hata vermemesi için 'index' diyebiliriz ama doğrusu blueprint adıyla çağırmaktır.
            # Biz standart olarak 'main.index' kullanımına hazırlık yapıyoruz.
            return redirect(url_for('main.index')) 
        return f(*args, **kwargs)
    return decorated_function

# ----------------------------------------------------
# ROUTE'LAR (URL: /admin/...)
# ----------------------------------------------------

@admin_bp.route('/')
@admin_required
def dashboard():
    with get_db() as conn:
        cur = conn.cursor()
        
        # İstatistikler
        cur.execute("SELECT COUNT(*) FROM users")
        stats = {'users': cur.fetchone()[0]}
        cur.execute("SELECT COUNT(*) FROM routes")
        stats['routes'] = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM events")
        stats['events'] = cur.fetchone()[0]
        
        # Listeler
        cur.execute("SELECT user_id, username, email, role, created_at FROM users ORDER BY user_id DESC")
        users = cur.fetchall()
        
        cur.execute("SELECT event_id, title, status FROM events ORDER BY event_date DESC LIMIT 20")
        events = cur.fetchall()
        
        cur.execute("SELECT route_id, route_name FROM routes ORDER BY created_at DESC LIMIT 20")
        routes = cur.fetchall()
        
        # Tanımlamalar
        cur.execute("SELECT * FROM hobbies ORDER BY hobby_id DESC")
        hobbies = cur.fetchall()
        
        cur.execute("SELECT * FROM badges ORDER BY badge_id DESC")
        badges = cur.fetchall()
    
    return render_template('admin_dashboard.html', stats=stats, users=users, events=events, routes=routes, hobbies=hobbies, badges=badges)

@admin_bp.route('/delete_user/<int:user_id>')
@admin_required
def delete_user(user_id):
    if user_id == session['user_id']:
        flash("Kendini silemezsin!", "warning")
        return redirect(url_for('admin.dashboard'))
        
    with get_db() as conn:
        cur = conn.cursor()
        try:
            # 1. KULÜP KONTROLÜ (Başkan mı?)
            cur.execute("SELECT club_id FROM clubs WHERE owner_id = %s", (user_id,))
            owned_clubs = cur.fetchall()
            
            for club in owned_clubs:
                c_id = club[0]
                # Kulüpte başka üye var mı? (Admin hariç)
                cur.execute("SELECT user_id FROM club_members WHERE club_id = %s AND user_id != %s ORDER BY joined_at ASC LIMIT 1", (c_id, user_id))
                new_owner = cur.fetchone()
                
                if new_owner:
                    # Varsa başkanlığı devret
                    cur.execute("UPDATE clubs SET owner_id = %s WHERE club_id = %s", (new_owner[0], c_id))
                    cur.execute("UPDATE club_members SET role = 'admin' WHERE user_id = %s AND club_id = %s", (new_owner[0], c_id))
                else:
                    # Yoksa kulübü sil
                    cur.execute("DELETE FROM club_announcements WHERE club_id = %s", (c_id,))
                    cur.execute("DELETE FROM club_members WHERE club_id = %s", (c_id,))
                    cur.execute("DELETE FROM clubs WHERE club_id = %s", (c_id,))

            # 2. İÇERİK SAHİPLİĞİNİ BOŞA DÜŞÜR
            cur.execute("UPDATE routes SET creator_id = NULL WHERE creator_id = %s", (user_id,))
            cur.execute("UPDATE events SET organizer_id = NULL WHERE organizer_id = %s", (user_id,))

            # 3. KİŞİSEL VERİLERİ SİL
            # (Tek tek silme işlemleri CASCADE constraints olsa bile manuel temizlik güvenlidir)
            tables = ['friendships', 'notifications', 'user_badges', 'user_hobbies', 'participations', 'route_reviews', 'club_members']
            # Friendships tablosu özel durum (requester veya addressee olabilir)
            cur.execute("DELETE FROM friendships WHERE requester_id = %s OR addressee_id = %s", (user_id, user_id))
            
            # Diğer tablolar (user_id sütunu olanlar)
            for tbl in tables:
                if tbl != 'friendships':
                    # Tabloda user_id kolonu var mı kontrolü yapılabilir ama şemanızı biliyoruz, var.
                    try:
                        cur.execute(f"DELETE FROM {tbl} WHERE user_id = %s", (user_id,))
                    except: pass # Bazı tablolarda user_id olmayabilir veya isim farklıdır, pass geçiyoruz.

            # 4. KULLANICIYI SİL
            cur.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
            
            conn.commit()
            flash("Kullanıcı ve ilişkili veriler temizlendi.", "success")
            
        except Exception as e:
            # Context manager otomatik rollback yapar ama loglayalım
            current_app.logger.error(f"SİLME HATASI: {e}")
            flash(f"Silme sırasında hata oluştu: {e}", "danger")
        
    return redirect(url_for('admin.dashboard'))

@admin_bp.route('/delete_content/<type>/<int:id>')
@admin_required
def delete_content(type, id):
    with get_db() as conn:
        cur = conn.cursor()
        try:
            if type == 'event':
                cur.execute("DELETE FROM notifications WHERE message LIKE %s", (f"%etkinliği iptal edildi%",))
                cur.execute("DELETE FROM participations WHERE event_id = %s", (id,))
                cur.execute("DELETE FROM events WHERE event_id = %s", (id,))
            elif type == 'route':
                cur.execute("DELETE FROM stops WHERE route_id = %s", (id,))
                cur.execute("DELETE FROM route_reviews WHERE route_id = %s", (id,))
                cur.execute("DELETE FROM events WHERE route_id = %s", (id,)) 
                cur.execute("DELETE FROM routes WHERE route_id = %s", (id,))
            
            conn.commit()
            flash("İçerik silindi.", "success")
        except Exception as e:
            flash(f"Hata: {e}", "danger")
            
    return redirect(url_for('admin.dashboard'))

@admin_bp.route('/delete_hobby/<int:hobby_id>')
@admin_required
def delete_hobby(hobby_id):
    with get_db() as conn:
        cur = conn.cursor()
        try:
            cur.execute("DELETE FROM user_hobbies WHERE hobby_id = %s", (hobby_id,))
            cur.execute("DELETE FROM hobbies WHERE hobby_id = %s", (hobby_id,))
            conn.commit()
            flash("İlgi alanı silindi.", "success")
        except Exception as e:
            flash(f"Hata: {e}", "danger")
            
    return redirect(url_for('admin.dashboard'))

@admin_bp.route('/delete_badge/<int:badge_id>')
@admin_required
def delete_badge(badge_id):
    with get_db() as conn:
        cur = conn.cursor()
        try:
            cur.execute("DELETE FROM user_badges WHERE badge_id = %s", (badge_id,))
            cur.execute("DELETE FROM badges WHERE badge_id = %s", (badge_id,))
            conn.commit()
            flash("Rozet silindi.", "success")
        except Exception as e:
            flash(f"Hata: {e}", "danger")
            
    return redirect(url_for('admin.dashboard'))

@admin_bp.route('/add_hobby', methods=['POST'])
@admin_required
def add_hobby():
    name = request.form['hobby_name']
    with get_db() as conn:
        cur = conn.cursor()
        try:
            cur.execute("INSERT INTO hobbies (hobby_name) VALUES (%s)", (name,))
            conn.commit()
            flash("İlgi alanı eklendi.", "success")
        except:
            flash("Hata oluştu.", "danger")
            
    return redirect(url_for('admin.dashboard'))

@admin_bp.route('/add_badge', methods=['POST'])
@admin_required
def add_badge():
    name = request.form['badge_name']
    desc = request.form['description']
    icon = request.form['icon_url']
    req_val = request.form['required_value']
    
    with get_db() as conn:
        cur = conn.cursor()
        try:
            cur.execute("""
                INSERT INTO badges (badge_name, description, icon_url, badge_type, required_value) 
                VALUES (%s, %s, %s, 'User', %s)
            """, (name, desc, icon, req_val))
            conn.commit()
            flash("Rozet eklendi.", "success")
        except Exception as e:
            current_app.logger.error(f"Hata Mesajı: {e}")
            print(e)
            flash("Hata oluştu.", "danger")
            
    return redirect(url_for('admin.dashboard'))