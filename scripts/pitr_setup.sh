#!/bin/bash
# ==============================================================================
# pitr_setup.sh: PostgreSQL Sürekli Arşivleme ve PITR Yapılandırma Rehberi
# ==============================================================================
# Bu dosya, Point-in-Time Recovery (Sıfır Veri Kayıplı Kurtarma) altyapısının
# kurulumunu otomatize eder ve gerekli adımları raporlar.

PROJECT_DIR="/Users/talip/Desktop/BLM4522/BLM4522-Veritabanı Yedekleme ve Felaketten Kurtarma Planı"
ARCHIVE_DIR="${PROJECT_DIR}/archive"
BACKUP_DIR="${PROJECT_DIR}/backups"

echo "=== PITR YAPILANDIRMA VE HAZIRLIK BASH BETİĞİ ==="
echo "1. Arşiv klasörleri oluşturuluyor..."
mkdir -p "${ARCHIVE_DIR}"
mkdir -p "${BACKUP_DIR}"
echo "Arşiv Klasörü: ${ARCHIVE_DIR}"
echo "Yedek Klasörü: ${BACKUP_DIR}"
echo ""

echo "2. postgresql.conf içerisine eklenmesi gereken satırlar:"
echo "--------------------------------------------------------"
echo "wal_level = replica"
echo "archive_mode = on"
echo "archive_command = 'cp %p \"${ARCHIVE_DIR}/%f\"'"
echo "--------------------------------------------------------"
echo "Bu ayarlar düzenlendikten sonra PostgreSQL servisi restart edilmelidir."
echo ""

echo "3. Fiziksel Base Backup alma komutu:"
echo "--------------------------------------------------------"
echo "pg_basebackup -h localhost -U postgres -D \"${BACKUP_DIR}/base_backup\" -Ft -z -P"
echo "--------------------------------------------------------"
echo ""

echo "4. Kaza Sonrası Kurtarma (Recovery) Adımları:"
echo "--------------------------------------------------------"
echo "a) PostgreSQL servisini durdurun."
echo "b) Mevcut data dizinindeki tüm dosyaları yedekleyip silin (Temiz kurulum için)."
echo "c) base_backup.tar.gz dosyasını data dizinine çıkartın."
echo "d) Data dizininde 'recovery.signal' adında boş bir dosya oluşturun."
echo "e) postgresql.conf veya postgresql.auto.conf dosyasına şu satırları ekleyin:"
echo "   restore_command = 'cp \"${ARCHIVE_DIR}/%f\" %p'"
echo "   recovery_target_time = '2026-06-10 11:15:30' # Kazadan hemen önceki zaman"
echo "f) PostgreSQL servisini yeniden başlatın."
echo "--------------------------------------------------------"
