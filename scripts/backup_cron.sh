#!/bin/bash
# ==============================================================================
# backup_cron.sh: PostgreSQL Otomatik ve Zamanlanmış Yedekleme Betiği
# ==============================================================================
# Bu betik, cron zamanlayıcı tarafından belirli aralıklarla çalıştırılmak
# üzere tasarlanmıştır. Veritabanını yedekler, doğrular ve eski yedekleri siler.

# Hata durumunda betiği durdur
set -e

# Proje ve Yedek Klasör Yollarını Tanımlama
PROJECT_DIR="/Users/talip/Desktop/BLM4522/BLM4522-Veritabanı Yedekleme ve Felaketten Kurtarma Planı"
BACKUP_DIR="${PROJECT_DIR}/backups"
LOG_FILE="${PROJECT_DIR}/backup_execution.log"

# PostgreSQL Bağlantı Parametreleri
DB_NAME="backup_demo"
DB_USER="talip"
DB_HOST="localhost"
DB_PORT="5432"

# Zaman Damgası Tanımı (Dosya isimleri için)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.dump"

# Loglama Başlangıcı
echo "======================================================================" >> "${LOG_FILE}"
echo "[$(date)] Yedekleme işlemi başlatıldı..." >> "${LOG_FILE}"

# Yedekleme dizinini kontrol et ve yoksa oluştur
if [ ! -d "${BACKUP_DIR}" ]; then
    mkdir -p "${BACKUP_DIR}"
    echo "[$(date)] Yedekleme klasörü oluşturuldu: ${BACKUP_DIR}" >> "${LOG_FILE}"
fi

# 1. pg_dump ile Sıkıştırılmış Mantıksal Yedek Alma (Custom Format)
echo "[$(date)] pg_dump çalıştırılıyor..." >> "${LOG_FILE}"
if pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -F c -b -v -f "${BACKUP_FILE}" 2>> "${LOG_FILE}"; then
    echo "[$(date)] Yedek dosyası başarıyla oluşturuldu: ${BACKUP_FILE}" >> "${LOG_FILE}"
else
    echo "[$(date)] HATA: Yedek alma işlemi başarısız!" >> "${LOG_FILE}"
    exit 1
fi

# 2. Yedek Bütünlüğü Doğrulama (Integrity Check)
echo "[$(date)] Yedek bütünlüğü test ediliyor..." >> "${LOG_FILE}"
if pg_restore -l "${BACKUP_FILE}" > /dev/null 2>&1; then
    echo "[$(date)] Doğrulama BAŞARILI: Yedek dosyası okunabiliyor." >> "${LOG_FILE}"
else
    echo "[$(date)] HATA: Yedek dosyası bozuk veya okunamaz durumda!" >> "${LOG_FILE}"
    exit 1
fi

# 3. Eski Yedekleri Temizleme (Retention Policy - 7 Günden Eski Yedekler Silinir)
echo "[$(date)] 7 günden eski yedekler temizleniyor..." >> "${LOG_FILE}"
find "${BACKUP_DIR}" -name "${DB_NAME}_backup_*.dump" -type f -mtime +7 -exec rm -v {} \; >> "${LOG_FILE}" 2>&1

echo "[$(date)] Yedekleme işlemi başarıyla tamamlandı." >> "${LOG_FILE}"
echo "======================================================================" >> "${LOG_FILE}"
