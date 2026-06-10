-- 01_schema.sql: Veritabanı Şeması ve Seeding Betiği

-- Eski tabloları temizleme (temiz başlangıç için)
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- 1. Customers (Müşteriler) Tablosu
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    country VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
);

-- 2. Orders (Siparişler) Tablosu
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    order_date TIMESTAMP NOT NULL DEFAULT NOW(),
    amount NUMERIC(10, 2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    shipping_address TEXT NOT NULL,
    tracking_number VARCHAR(50)
);

-- 3. Transactions (Ödeme İşlemleri) Tablosu
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL,
    transaction_status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
    transaction_date TIMESTAMP NOT NULL DEFAULT NOW(),
    card_brand VARCHAR(20)
);

-- Seeding: Müşteriler (50.000 Kayıt)
INSERT INTO customers (name, email, phone, country, created_at, status)
SELECT 
    'Müşteri ' || i AS name,
    'customer_' || i || '@yedeklemedemo.com' AS email,
    '+90555' || LPAD(i::text, 7, '0') AS phone,
    (ARRAY['Türkiye', 'Almanya', 'ABD', 'İngiltere', 'Fransa', 'İtalya', 'Japonya', 'Kanada', 'Hollanda', 'İspanya'])[floor(random() * 10) + 1] AS country,
    NOW() - (random() * 365) * INTERVAL '1 day' AS created_at,
    (ARRAY['ACTIVE', 'INACTIVE', 'SUSPENDED'])[floor(random() * 3) + 1] AS status
FROM generate_series(1, 50000) AS i;

-- Seeding: Siparişler (500.000 Kayıt)
INSERT INTO orders (customer_id, order_date, amount, status, shipping_address, tracking_number)
SELECT 
    floor(random() * 50000 + 1)::INT AS customer_id,
    NOW() - (random() * 180) * INTERVAL '1 day' AS order_date,
    (random() * 4900 + 100)::NUMERIC(10, 2) AS amount,
    (ARRAY['COMPLETED', 'PENDING', 'SHIPPED', 'CANCELLED'])[floor(random() * 4) + 1] AS status,
    'Sokak No ' || floor(random() * 100 + 1) || ', Daire ' || floor(random() * 10 + 1) || ', Şehir ' || floor(random() * 81 + 1) AS shipping_address,
    'TRK' || floor(random() * 900000000 + 100000000)::BIGINT AS tracking_number
FROM generate_series(1, 500000) AS i;

-- Seeding: Ödeme İşlemleri (500.000 Kayıt)
INSERT INTO transactions (order_id, payment_method, transaction_status, transaction_date, card_brand)
SELECT 
    i AS order_id,
    (ARRAY['CREDIT_CARD', 'BANK_TRANSFER', 'EFT', 'MOBILE_PAYMENT'])[floor(random() * 4) + 1] AS payment_method,
    (ARRAY['SUCCESS', 'FAILED', 'PENDING'])[floor(random() * 3) + 1] AS transaction_status,
    o.order_date + (random() * 5) * INTERVAL '1 minute' AS transaction_date,
    (ARRAY['Visa', 'Mastercard', 'Troy', 'Amex'])[floor(random() * 4) + 1] AS card_brand
FROM generate_series(1, 500000) AS i
JOIN orders o ON o.id = i;

-- Hızlı Cascade Delete ve Join performansı için Dış Anahtar (Foreign Key) İndeksleri
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_transactions_order_id ON transactions(order_id);

