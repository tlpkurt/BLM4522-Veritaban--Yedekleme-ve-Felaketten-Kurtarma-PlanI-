-- 03_replication_monitoring.sql: Replikasyon (Database Mirroring) İzleme Sorguları

-- ==========================================
-- ADIM 1: Sunucu Rolünün Tespiti (Primary mi Standby mı?)
-- ==========================================
-- pg_is_in_recovery() fonksiyonu sunucunun durumunu döner.
-- Çıktı FALSE ise sunucu yazma yapılabilen BİRİNCİL (Primary) sunucudur.
-- Çıktı TRUE ise sunucu salt-okunur YEDEK (Standby / Mirror) sunucudur.
SELECT pg_is_in_recovery() AS is_standby_node;

-- ==========================================
-- ADIM 2: Birincil Sunucu Üzerinde Replikasyon Durumu (Primary Node)
-- ==========================================
-- Bu sorgu, birincil sunucuya bağlı olan tüm Standby (Mirror) sunucuları listeler.
-- Replikasyon tipi (streaming), durumu (streaming, startup), IP adresi ve gecikme metrikleri izlenir.
SELECT 
    application_name,
    client_addr AS standby_ip,
    state AS replikasyon_durumu,
    sync_state AS senkronizasyon_tipi, -- sync, async, potential
    sync_priority AS oncelik,
    -- WAL yazma, gönderme ve yedekleme noktaları arasındaki farklar (Log Sequence Numbers - LSN)
    pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) AS sent_lag_bytes,
    pg_wal_lsn_diff(sent_lsn, write_lsn) AS write_lag_bytes,
    pg_wal_lsn_diff(write_lsn, flush_lsn) AS flush_lag_bytes,
    pg_wal_lsn_diff(flush_lsn, replay_lsn) AS replay_lag_bytes,
    -- Toplam gecikme miktarı (bayt cinsinden)
    pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS toplam_gecikme_bayt
FROM pg_stat_replication;

-- ==========================================
-- ADIM 3: Yedek Sunucu Üzerinde WAL Alıcısı Durumu (Standby Node)
-- ==========================================
-- Sadece Standby sunucu üzerinde çalışır ve ana sunucudan gelen WAL verilerinin durumunu gösterir.
SELECT 
    status,
    receive_start_lsn,
    written_lsn,
    flushed_lsn,
    last_msg_send_time,
    last_msg_receipt_time,
    -- Birincil sunucu ile son haberleşme zamanı
    NOW() - last_msg_receipt_time AS baglanti_gecikmesi_suresi,
    conninfo AS baglanti_bilgisi
FROM pg_stat_wal_receiver;

-- ==========================================
-- ADIM 4: Sürekli Arşivleme (WAL Archiving) Sağlık Durumu
-- ==========================================
-- Bu sorgu, yedekleme dosyalarının (WAL) belirlenen depolama alanına 
-- başarıyla yazılıp yazılmadığını kontrol eder.
SELECT 
    archived_count AS basarili_arsivlenen_wal_sayisi,
    failed_count AS basarisiz_arsivleme_denemesi,
    last_archived_wal AS son_arsivlenen_wal_dosyasi,
    last_archived_time AS son_arsivleme_zamani,
    last_failed_wal AS son_basarisiz_wal_dosyasi,
    last_failed_time AS son_basarisiz_arsivleme_zamani
FROM pg_stat_archiver;
