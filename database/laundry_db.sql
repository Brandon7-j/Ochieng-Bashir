-- =====================================================
-- Web Based Laundry Management System - MySQL database
-- =====================================================

CREATE DATABASE IF NOT EXISTS laundry_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE laundry_db;

-- Drop in reverse order so you can re-run this file safely
DROP TABLE IF EXISTS receipts;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS bills;
DROP TABLE IF EXISTS garments;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS service_items;
DROP TABLE IF EXISTS users;

-- 1. USERS: owner, staff and customers in one table (role column)
CREATE TABLE users (
    user_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    phone         VARCHAR(15)  NOT NULL UNIQUE,            -- no repeated phone numbers (FR10)
    email         VARCHAR(100) NULL,
    username      VARCHAR(50)  NULL UNIQUE,                -- used by owner and staff
    password_hash VARCHAR(255) NOT NULL,                   -- hashed only, never plain text
    role          ENUM('owner','staff','customer') NOT NULL,
    status        ENUM('active','inactive') NOT NULL DEFAULT 'active',  -- FR05 deactivate
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. SERVICE_ITEMS: price list set by the owner (FR08, FR09)
CREATE TABLE service_items (
    service_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(80) NOT NULL,
    unit         VARCHAR(20) NOT NULL,                     -- e.g. kg, piece
    unit_price   DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    is_active    TINYINT(1) NOT NULL DEFAULT 1,
    defined_by   INT UNSIGNED NOT NULL,
    FOREIGN KEY (defined_by) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- 3. ORDERS: one customer, received by one staff member (FR13)
CREATE TABLE orders (
    order_no            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id         INT UNSIGNED NOT NULL,
    staff_id            INT UNSIGNED NOT NULL,
    date_received       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expected_ready_date DATE NULL,
    status ENUM('received','in_process','ready','collected') NOT NULL DEFAULT 'received',
    FOREIGN KEY (customer_id) REFERENCES users(user_id),
    FOREIGN KEY (staff_id)    REFERENCES users(user_id)
) ENGINE=InnoDB;

-- 4. GARMENTS: each garment tied to one order (FR14, FR16)
CREATE TABLE garments (
    garment_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_no       INT UNSIGNED NOT NULL,
    service_id     INT UNSIGNED NOT NULL,
    tag_no         VARCHAR(20) NOT NULL UNIQUE,            -- unique garment tag
    garment_type   VARCHAR(50) NOT NULL,
    colour         VARCHAR(30) NULL,
    quantity       INT UNSIGNED NOT NULL DEFAULT 1 CHECK (quantity > 0),  -- zero is rejected
    condition_note VARCHAR(255) NULL,
    status ENUM('received','in_process','ready','collected') NOT NULL DEFAULT 'received',
    FOREIGN KEY (order_no)   REFERENCES orders(order_no),
    FOREIGN KEY (service_id) REFERENCES service_items(service_id)
) ENGINE=InnoDB;

-- 5. BILLS: one bill per order (UNIQUE order_no) (FR18)
CREATE TABLE bills (
    bill_no        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_no       INT UNSIGNED NOT NULL UNIQUE,
    amount_due     DECIMAL(10,2) NOT NULL,
    balance        DECIMAL(10,2) NOT NULL DEFAULT 0,
    payment_status ENUM('unpaid','paid') NOT NULL DEFAULT 'unpaid',
    generated_on   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_no) REFERENCES orders(order_no)
) ENGINE=InnoDB;

-- 6. PAYMENTS: M-Pesa attempts. A bill can have many (FR19, FR20)
CREATE TABLE payments (
    payment_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bill_no             INT UNSIGNED NOT NULL,
    amount              DECIMAL(10,2) NOT NULL,
    phone_number        VARCHAR(15) NOT NULL,
    checkout_request_id VARCHAR(100) NULL UNIQUE,          -- from the Daraja STK push
    mpesa_receipt_code  VARCHAR(20)  NULL UNIQUE,          -- no repeated M-Pesa codes
    status     ENUM('pending','paid','failed') NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paid_at    DATETIME NULL,
    FOREIGN KEY (bill_no) REFERENCES bills(bill_no)
) ENGINE=InnoDB;

-- 7. RECEIPTS: one receipt per payment (UNIQUE payment_id) (FR21)
CREATE TABLE receipts (
    receipt_no INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payment_id INT UNSIGNED NOT NULL UNIQUE,
    amount     DECIMAL(10,2) NOT NULL,
    issued_on  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_id) REFERENCES payments(payment_id)
) ENGINE=InnoDB;

-- Helpful indexes for fast search (NFR03)
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status   ON orders(status);

-- =====================================================
-- SAMPLE DATA (fake data only). All passwords = "password"
-- =====================================================

INSERT INTO users (full_name, phone, email, username, password_hash, role) VALUES
('Shop Owner',   '0700000001', 'owner@example.com', 'owner',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'owner'),
('Mary Counter', '0700000002', 'mary@example.com',  'staff1', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'staff'),
('Jane Wanjiru', '0712345678', 'jane@example.com',  NULL,     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'customer'),
('Brian Otieno', '0723456789', 'brian@example.com', NULL,     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'customer');

INSERT INTO service_items (service_name, unit, unit_price, defined_by) VALUES
('Wash and Fold',        'kg',    150.00, 1),
('Dry Cleaning - Suit',  'piece', 600.00, 1),
('Ironing',              'piece',  50.00, 1);

-- Order 1: Jane (fully paid)
INSERT INTO orders (customer_id, staff_id, expected_ready_date, status)
VALUES (3, 2, DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'ready');

INSERT INTO garments (order_no, service_id, tag_no, garment_type, colour, quantity, condition_note, status) VALUES
(1, 1, 'LT-0001', 'Mixed clothes', 'Assorted', 3, 'Weight in kg', 'ready'),
(1, 2, 'LT-0002', 'Suit',          'Black',    1, 'Small stain on sleeve', 'ready');

-- Bill = (3 x 150) + (1 x 600) = 1050
INSERT INTO bills (order_no, amount_due, balance, payment_status)
VALUES (1, 1050.00, 0.00, 'paid');

INSERT INTO payments (bill_no, amount, phone_number, checkout_request_id, mpesa_receipt_code, status, paid_at)
VALUES (1, 1050.00, '0712345678', 'ws_CO_SAMPLE_0001', 'QWE123ABCD', 'paid', NOW());

INSERT INTO receipts (payment_id, amount) VALUES (1, 1050.00);

-- Order 2: Brian (unpaid)
INSERT INTO orders (customer_id, staff_id, expected_ready_date, status)
VALUES (4, 2, DATE_ADD(CURDATE(), INTERVAL 1 DAY), 'in_process');

INSERT INTO garments (order_no, service_id, tag_no, garment_type, colour, quantity, status)
VALUES (2, 3, 'LT-0003', 'Shirts', 'White', 5, 'in_process');

-- Bill = 5 x 50 = 250
INSERT INTO bills (order_no, amount_due, balance, payment_status)
VALUES (2, 250.00, 250.00, 'unpaid');

-- =====================================================
-- TEST QUERIES (the four owner reports, FR24 to FR27)
-- =====================================================

-- FR24: daily sales for today
SELECT DATE(paid_at) AS sales_date, SUM(amount) AS total_sales
FROM payments
WHERE status = 'paid' AND DATE(paid_at) = CURDATE()
GROUP BY DATE(paid_at);

-- FR25: outstanding balances by customer
SELECT u.full_name, u.phone, b.bill_no, b.balance
FROM bills b
JOIN orders o ON o.order_no = b.order_no
JOIN users u  ON u.user_id = o.customer_id
WHERE b.payment_status = 'unpaid';

-- FR26: orders grouped by status
SELECT status, COUNT(*) AS total_orders
FROM orders
GROUP BY status;

-- FR27: order history of one customer (Jane = user_id 3)
SELECT o.order_no, o.date_received, o.status, b.amount_due
FROM orders o
LEFT JOIN bills b ON b.order_no = o.order_no
WHERE o.customer_id = 3;