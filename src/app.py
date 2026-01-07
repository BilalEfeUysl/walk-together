import os
import logging
from logging.handlers import RotatingFileHandler
from flask import Flask
from dotenv import load_dotenv

# Blueprintleri içe aktar
from blueprints.auth import auth_bp
from blueprints.admin import admin_bp
from blueprints.main import main_bp

# .env dosyasını yükle
load_dotenv()

app = Flask(__name__)

# --- AYARLAR ---
app.secret_key = os.getenv('SECRET_KEY', 'varsayilan_guvensiz_anahtar')

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'static', 'uploads')
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# --- LOGGING (HATA KAYIT) AYARLARI ---
# Logs klasörü yoksa oluştur
if not os.path.exists('logs'):
    os.mkdir('logs')

# Log dosyasını ayarla: En fazla 10KB olsun, dolunca yedeğini alıp yenisini açsın (max 10 yedek)
file_handler = RotatingFileHandler('logs/walktogether.log', maxBytes=10240, backupCount=10)

# Log formatı: [Tarih Saat] [Hata Seviyesi]: Mesaj [Dosya:Satır]
file_handler.setFormatter(logging.Formatter(
    '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
))

# Hangi seviyedeki hataları yazsın? (INFO ve üzeri: INFO, WARNING, ERROR, CRITICAL)
file_handler.setLevel(logging.INFO)
app.logger.addHandler(file_handler)

app.logger.setLevel(logging.INFO)
app.logger.info('WalkTogether uygulaması başlatıldı.')

# --- BLUEPRINT KAYITLARI ---
app.register_blueprint(auth_bp)
app.register_blueprint(admin_bp)
app.register_blueprint(main_bp)

if __name__ == '__main__':
    app.run(debug=True)