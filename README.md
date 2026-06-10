# PostgreSQL Veritabanı Yedekleme ve Felaketten Kurtarma Planı Projesi (CLI & pgAdmin Sürümü)

Bu proje, **BLM4522** dersi kapsamında PostgreSQL veritabanı motoru üzerinde yedekleme planlarının tasarlanması, sürekli işlem günlüğü (WAL) arşivleme, Point-in-Time Recovery (PITR) ile sıfır veri kayıplı kurtarma senaryoları ve veri aynalama (replication) izleme süreçlerini uygulamalı olarak gösterir.

Projede **50.000 Müşteri**, **500.000 Sipariş** ve **500.000 Ödeme İşlemi** (toplamda 1 Milyondan fazla satır) barındıran ilişkisel bir veri tabanı şeması üzerinde çalışılmıştır. Operasyonel işlemler için PostgreSQL'in standart komut satırı aracı (`psql`, `pg_dump`, `pg_restore`) ve görsel yönetim aracı olan **pgAdmin 4** tercih edilmiştir.

---

## 📂 Proje Dizin Yapısı

```
├── sql/
│   ├── 01_schema.sql                  # Veritabanı şeması ve 1.05M satırlık seeding betiği
│   ├── 02_disaster_scenario.sql       # Kaza ile veri silme senaryosu ve doğrulama sorguları
│   ├── 03_replication_monitoring.sql  # Replikasyon/Aynalama izleme ve WAL arşiv sağlık sorguları
│   └── presentation_cheatsheet.sql    # Sunum/Video kaydı sırasında kullanılacak toplu SQL komutları
│
├── scripts/
│   ├── backup_cron.sh                 # Zamanlanmış otomatik yedekleme ve bütünlük kontrolü betiği
│   └── pitr_setup.sh                  # WAL sürekli arşivleme ve PITR kurulum yönergeleri betiği
│
├── report.md                          # Akademik standartlarda detaylı Türkçe proje raporu
└── README.md                          # Kurulum ve hızlı başlangıç kılavuzu (Bu dosya)
```

---

## ⚙️ Kurulum ve Yapılandırma

### 1. PostgreSQL Veritabanının Hazırlanması
1. Terminal veya komut satırını açın.
2. `backup_demo` adında yeni bir veritabanı oluşturun:
   ```bash
   psql -d postgres -c "CREATE DATABASE backup_demo;"
   ```
3. Şema ve veri üretim betiğini çalıştırın (bu işlem yaklaşık 5-10 saniye sürer):
   ```bash
   psql -d backup_demo -f sql/01_schema.sql
   ```

### 2. Sürekli Arşivleme (WAL) ve PITR Hazırlığı
PostgreSQL'in çökme durumlarında sıfır veri kaybı sunabilmesi için sürekli arşivlemeyi aktifleştirmeliyiz:
1. `scripts/pitr_setup.sh` betiğini çalıştırarak gerekli klasörleri oluşturun ve ayar parametrelerini görüntüleyin:
   ```bash
   ./scripts/pitr_setup.sh
   ```
2. PostgreSQL yapılandırma dosyanızı (`postgresql.conf`) açın ve aşağıdaki satırları ekleyin/düzenleyin:
   ```ini
   wal_level = replica
   archive_mode = on
   archive_command = 'cp %p /Users/talip/Desktop/BLM4522/BLM4522-Veritabanı Yedekleme ve Felaketten Kurtarma Planı/archive/%f'
   ```
3. Ayarların geçerli olması için PostgreSQL servisini yeniden başlatın:
   - macOS (Homebrew): `brew services restart postgresql` veya `pg_ctl -D /opt/homebrew/var/postgres restart`

---

## ⚡ Operasyonel Senaryoların Çalıştırılması

### A. Otomatik Yedekleme ve Bütünlük Doğrulaması (Cron)
Hazırladığımız `backup_cron.sh` betiği veritabanını sıkıştırılmış biçimde yedekler, ardından `pg_restore -l` ile yedeğin okunabilirliğini (bütünlüğünü) test eder, 7 günden eski yedekleri siler ve durumunu günlüğe (log) kaydeder.
1. Betiği terminalden manuel olarak çalıştırıp test edin:
   ```bash
   ./scripts/backup_cron.sh
   ```
2. Günlük log kaydını inceleyin:
   ```bash
   cat backup_execution.log
   ```

### B. Felaket ve Kurtarma Senaryoları (Disaster & Recovery)
1. **Mantıksal Yedekten Geri Yükleme:**
   ```bash
   pg_restore -h localhost -U postgres -d backup_demo --clean ./backups/backup_demo_backup_<tarih_saat>.dump
   ```
2. **Point-in-Time Recovery (PITR) (WAL Logları ile Sıfır Kayıplı Geri Dönüş):**
   - Veritabanı servisini durdurun.
   - Fiziksel `base_backup` dosyasını data dizinine çıkartın.
   - Veri dizininde boş bir `recovery.signal` dosyası oluşturun.
   - `postgresql.conf` içerisine aşağıdaki ayarları ekleyin ve servisi başlatın:
     ```ini
     restore_command = 'cp /Users/talip/Desktop/BLM4522/BLM4522-Veritabanı Yedekleme ve Felaketten Kurtarma Planı/archive/%f %p'
     recovery_target_time = '2026-06-10 11:15:30' # Kazadan hemen önceki zaman damgası
     ```

---

## 📊 Replikasyon ve Veri Aynalamanın İzlenmesi
pgAdmin 4 Sorgu Aracından veya terminalden replikasyon durumlarını ve log gecikmelerini izlemek için `sql/03_replication_monitoring.sql` dosyasındaki DMV sorgularını kullanabilirsiniz.
- `pg_stat_replication` sorgusu, Standby (ayna) sunucularının birincil sunucuya olan gecikmesini (lag) izlemenizi sağlar.
- `pg_stat_archiver` sorgusu, WAL arşivleme sürecinin başarılı ve başarısız denemelerini takip etmenizi sağlar.
