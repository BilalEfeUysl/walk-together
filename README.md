## 📂 Klasör Yapısı

Proje dizinleri aşağıdaki gibi düzenlenmiştir:

```text
walk-together/
│
├── database/              # 🗄️ SQL Dosyaları (Veritabanı kalbi burada)
│   ├── 01_create_tables.sql   # Tablo oluşturma kodları
│   ├── 02_insert_data.sql     # Test verileri (Dummy Data)
│   └── 03_advanced_features.sql # Trigger, View ve Fonksiyonlar
│
├── docs/                  # 📄 Dokümantasyon
│   └── er-diagram.png     # Veritabanı ER Diyagramı (Tasarım)
│
├── src/                   # 💻 Uygulama Kodları 
│   └── (Yakında eklenecek...)
│
└── README.md              # 📖 Proje Rehberi


WINDOWS Başlatma

- .\venv\Scripts\activate
- python src/app.py 