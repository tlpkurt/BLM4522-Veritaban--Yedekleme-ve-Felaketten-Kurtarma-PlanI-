-- presentation_cheatsheet.sql - Sunum Akışı Hızlı Kod Dosyası

-- ADIM 1: Veritabanı Oluşturma (Terminal CLI)
-- psql -d postgres -c "CREATE DATABASE backup_demo;"
-- psql -d backup_demo -f sql/01_schema.sql

-- ADIM 2: Kaza Öncesi Durum Kontrolü
SELECT COUNT(*) AS toplam_musteri FROM customers;
SELECT COUNT(*) AS toplam_siparis FROM orders;
SELECT COUNT(*) AS toplam_odeme FROM transactions;

-- ADIM 3: Mantıksal Sıkıştırılmış Yedek Alma (Terminal CLI)
-- pg_dump -h localhost -U talip -d backup_demo -F c -b -v -f "/Users/talip/Desktop/BLM4522/BLM4522-Veritabanı Yedekleme ve Felaketten Kurtarma Planı/backups/backup_demo_full.dump"

-- ADIM 4: Yedek Sonrası Yeni Kritik İşlem Girişi
INSERT INTO customers (id, name, email, phone, country, status) 
VALUES (999999, 'VIP Müşteri A.Ş.', 'vip@muste.ri', '+902129998877', 'Türkiye', 'ACTIVE');

INSERT INTO orders (id, customer_id, order_date, amount, status, shipping_address, tracking_number)
VALUES (999999, 999999, NOW(), 750000.00, 'COMPLETED', 'VIP Plaza Kat 45, Levent, İstanbul', 'TRK_VIP_001');

INSERT INTO transactions (order_id, payment_method, transaction_status, transaction_date, card_brand)
VALUES (999999, 'BANK_TRANSFER', 'SUCCESS', NOW(), NULL);

-- Kurtarma Zaman Noktası (PITR için):
SELECT NOW() AS kazadan_hemen_onceki_zaman;

-- ADIM 5: Kaza ile Verilerin Silinmesi
DELETE FROM orders;

-- Hasar Tespiti:
SELECT COUNT(*) AS toplam_siparis_kaza_sonrasi FROM orders;

-- ADIM 6: Mantıksal Yedekten Geri Yükleme (Terminal CLI)
-- pg_restore -h localhost -U talip -d backup_demo --clean "/Users/talip/Desktop/BLM4522/BLM4522-Veritabanı Yedekleme ve Felaketten Kurtarma Planı/backups/backup_demo_full.dump"

-- Geri Yükleme Sonrası Kayıp Veri Kontrolü:
SELECT COUNT(*) AS kurtarilan_siparis FROM orders;
SELECT * FROM customers WHERE id = 999999; -- (Kayıt bulunamayacak!)

-- ADIM 7: Fiziksel Sürekli Arşivleme ve PITR Kurulumu
-- postgresql.conf:
-- wal_level = replica
-- archive_mode = on
-- archive_command = 'cp %p "/Users/talip/Desktop/BLM4522/BLM4522-Veritabanı Yedekleme ve Felaketten Kurtarma Planı/archive/%f"'

-- Fiziksel Base Backup (Terminal CLI):
-- pg_basebackup -h localhost -U talip -D "/Users/talip/Desktop/BLM4522/BLM4522-Veritabanı Yedekleme ve Felaketten Kurtarma Planı/backups/base_backup" -Ft -z -P

-- ADIM 8: PITR Kurtarma Adımları (Terminal CLI)
-- 1. Servisi Durdur
-- 2. Data dizinini temizle ve base_backup'ı aç
-- 3. recovery.signal dosyası oluştur
-- 4. postgresql.conf'a ekle:
--    restore_command = 'cp "/Users/talip/Desktop/BLM4522/BLM4522-Veritabanı Yedekleme ve Felaketten Kurtarma Planı/archive/%f" %p'
--    recovery_target_time = '2026-06-10 11:15:30' (ADIM 4'teki zaman damgası)
-- 5. Servisi Başlat

-- ADIM 9: PITR Sonrası Durum Doğrulama
SELECT COUNT(*) AS pitr_kurtarilan_siparis FROM orders;
SELECT * FROM customers WHERE id = 999999; -- (Başarıyla kurtarıldı!)

-- ADIM 10: Zamanlanmış Cron Yedeklemeyi Çalıştırma (Terminal CLI)
-- ./scripts/backup_cron.sh
-- cat backup_execution.log

-- ADIM 11: Replikasyon (Aynalama) İzleme
SELECT pg_is_in_recovery() AS is_standby_node;

SELECT application_name, client_addr AS standby_ip, state, sync_state,
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes
FROM pg_stat_replication;

SELECT archived_count, failed_count, last_archived_time FROM pg_stat_archiver;
