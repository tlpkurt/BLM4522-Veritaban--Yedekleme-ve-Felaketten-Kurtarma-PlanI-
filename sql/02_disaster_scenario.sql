-- 02_disaster_scenario.sql: Veri Silme ve Felaketten Kurtarma Senaryoları

-- ==========================================
-- ADIM 1: Durum Analizi (Kaza Öncesi Mevcut Durum)
-- ==========================================
SELECT COUNT(*) AS toplam_musteri FROM customers;
SELECT COUNT(*) AS toplam_siparis FROM orders;
SELECT COUNT(*) AS toplam_odeme FROM transactions;

-- ==========================================
-- ADIM 2: Kritik Yeni Verilerin Girişi ve Zaman Tespiti
-- ==========================================
-- Önemli bir iş anlaşması yapılıyor ve kritik siparişler sisteme giriliyor:
INSERT INTO customers (id, name, email, phone, country, status) 
VALUES (999999, 'VIP Müşteri A.Ş.', 'vip@muste.ri', '+902129998877', 'Türkiye', 'ACTIVE');

INSERT INTO orders (id, customer_id, order_date, amount, status, shipping_address, tracking_number)
VALUES (999999, 999999, NOW(), 750000.00, 'COMPLETED', 'VIP Plaza Kat 45, Levent, İstanbul', 'TRK_VIP_001');

INSERT INTO transactions (order_id, payment_method, transaction_status, transaction_date, card_brand)
VALUES (999999, 'BANK_TRANSFER', 'SUCCESS', NOW(), NULL);

-- Kurtarma Noktası (Point-in-Time) için tam zaman damgasını alıyoruz:
-- Bu zaman damgası PITR işleminde hedef kurtarma zamanı (recovery_target_time) olarak kullanılacaktır.
SELECT NOW() AS kurtarma_hedef_zamani;

-- ==========================================
-- ADIM 3: Felaket Simülasyonu (Kaza ile Verilerin Silinmesi)
-- ==========================================
-- Kaza ile WHERE koşulu unutularak tüm sipariş ve ödeme kayıtları siliniyor:
DELETE FROM orders;

-- Silme işleminden sonra verileri kontrol ediyoruz (Hasar tespiti):
SELECT COUNT(*) AS toplam_siparis_kaza_sonrasi FROM orders;
SELECT COUNT(*) AS toplam_odeme_kaza_sonrasi FROM transactions;
-- Görüldüğü üzere sipariş tablomuz tamamen boşalmıştır.

-- ==========================================
-- ADIM 4: Kurtarma Sonrası Doğrulama
-- ==========================================
-- (Yedekten geri yükleme veya PITR adımları uygulandıktan sonra çalıştırılacaktır)
-- Beklenen Durum: Silinen 500.001 sipariş ve VIP Müşteri A.Ş. dahil tüm verilerin eksiksiz geri gelmesi.

SELECT COUNT(*) AS kurtarilan_musteri FROM customers;
SELECT COUNT(*) AS kurtarilan_siparis FROM orders;
SELECT COUNT(*) AS kurtarilan_odeme FROM transactions;

-- VIP siparişimizin başarıyla kurtarıldığını test ediyoruz:
SELECT * FROM customers WHERE id = 999999;
SELECT * FROM orders WHERE id = 999999;
