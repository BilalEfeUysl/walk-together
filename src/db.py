import os
import psycopg2
from contextlib import contextmanager
from dotenv import load_dotenv

# .env dosyasını yükle
load_dotenv()

@contextmanager
def get_db():
    """
    Veritabanı bağlantısını güvenli bir şekilde yöneten Context Manager.
    Kullanımı:
    with get_db() as conn:
        cur = conn.cursor()
        ...
    """
    conn = None
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            database=os.getenv('DB_NAME', 'postgres'),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASS', 'sifreniz'),
            port=os.getenv('DB_PORT', '5432')
        )
        yield conn
    except Exception as e:
        # Hata olursa işlemleri geri al (Rollback)
        if conn:
            conn.rollback()
        print(f"Veritabanı işlem hatası: {e}")
        raise e
    finally:
        # İşlem bitince (başarılı veya hatalı) bağlantıyı mutlaka kapat
        if conn:
            conn.close()

# Eski kodların bozulmaması için (şimdilik) bu fonksiyonu da tutuyoruz.
# Ancak ileride tamamen 'with get_db()' yapısına geçeceğiz.
def get_db_connection():
    try:
        return psycopg2.connect(
            host=os.getenv('DB_HOST'),
            database=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASS'),
            port=os.getenv('DB_PORT')
        )
    except Exception as e:
        print(f"Bağlantı hatası: {e}")
        return None