from flask import Blueprint, render_template, request, redirect, url_for, session, flash, current_app
from db import get_db

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        with get_db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT * FROM users WHERE username = %s AND password = %s", (username, password))
            user = cur.fetchone()
        
        if user:
            session['user_id'] = user[0]
            session['username'] = user[1]
            session['role'] = user[4]
            flash('Giriş başarılı!', 'success')
            
            if user[3] == 'admin':
                # Admin paneli yönlendirmesi
                return redirect(url_for('admin.dashboard')) 
            else:
                # [DÜZELTİLDİ] 'index' -> 'main.index'
                return redirect(url_for('main.index'))
        else:
            flash('Hatalı kullanıcı adı veya şifre.', 'danger')
            
    return render_template('login.html')

@auth_bp.route('/register/', methods=['GET', 'POST'])
def register():
    with get_db() as conn:
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
                # [DÜZELTİLDİ] 'auth.login' (Zaten doğruydu ama emin olalım)
                return redirect(url_for('auth.login')) 
            except Exception as e:
                current_app.logger.error(f"KAYIT HATASI: {e}") # <-- GÜNCELLENDİ (Log dosyasına yazar)
                flash('Kayıt başarısız. Kullanıcı adı veya e-posta kullanımda olabilir.', 'danger')

        cur.execute("SELECT * FROM hobbies")
        all_hobbies = cur.fetchall()
            
    return render_template('register.html', hobbies=all_hobbies)

@auth_bp.route('/logout')
def logout():
    session.clear()
    flash('Çıkış yapıldı.', 'info')
    # [DÜZELTİLDİ] 'index' -> 'main.index'
    return redirect(url_for('main.index'))