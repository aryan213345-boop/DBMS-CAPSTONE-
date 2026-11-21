-- ============================================================
-- PROJECT 1: Smart Campus Resource & Lab Booking System
-- CORRECTED VERSION (MySQL 8.0.16+ recommended; uses CHECK constraints, CTEs and window functions)
-- WARNING: This script drops and recreates the smart_campus_booking database.
-- ============================================================

DROP DATABASE IF EXISTS smart_campus_booking;
CREATE DATABASE smart_campus_booking;
USE smart_campus_booking;

-- ============================================================
-- 1. TABLES
-- ============================================================

CREATE TABLE ROLE (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200)
);

CREATE TABLE DEPARTMENT (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_code VARCHAR(10) NOT NULL UNIQUE,
    dept_name VARCHAR(100) NOT NULL,
    building VARCHAR(50),
    contact_email VARCHAR(100)
);

CREATE TABLE `USER` (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    role_id INT NOT NULL,
    dept_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES ROLE(role_id),
    FOREIGN KEY (dept_id) REFERENCES DEPARTMENT(dept_id)
);

CREATE TABLE LOCATION (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    location_code VARCHAR(20) NOT NULL UNIQUE,
    location_name VARCHAR(100) NOT NULL,
    building VARCHAR(50) NOT NULL,
    floor INT,
    capacity INT CHECK (capacity > 0),
    location_type ENUM('Lab', 'Seminar Hall', 'Smart Classroom', 'Workshop', 'Other') NOT NULL,
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES DEPARTMENT(dept_id)
);

CREATE TABLE RESOURCE_TYPE (
    type_id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200)
);

CREATE TABLE RESOURCE (
    resource_id INT PRIMARY KEY AUTO_INCREMENT,
    resource_code VARCHAR(30) NOT NULL UNIQUE,
    resource_name VARCHAR(100) NOT NULL,
    type_id INT NOT NULL,
    location_id INT NOT NULL,
    status ENUM('Available', 'Under Maintenance', 'Retired', 'Reserved') DEFAULT 'Available',
    purchase_date DATE,
    last_maintenance DATE,
    description TEXT,
    FOREIGN KEY (type_id) REFERENCES RESOURCE_TYPE(type_id),
    FOREIGN KEY (location_id) REFERENCES LOCATION(location_id)
);

CREATE TABLE BOOKING (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_code VARCHAR(30) NOT NULL UNIQUE,
    user_id INT NOT NULL,
    purpose VARCHAR(255) NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected', 'Cancelled', 'Completed') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    CONSTRAINT chk_time CHECK (end_datetime > start_datetime),
    FOREIGN KEY (user_id) REFERENCES `USER`(user_id)
);

CREATE TABLE BOOKING_ITEM (
    booking_item_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL,
    resource_id INT NOT NULL,
    quantity INT DEFAULT 1 CHECK (quantity > 0),
    FOREIGN KEY (booking_id) REFERENCES BOOKING(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES RESOURCE(resource_id),
    UNIQUE KEY uk_booking_resource (booking_id, resource_id)
);

CREATE TABLE APPROVAL (
    approval_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL UNIQUE,
    approver_id INT NOT NULL,
    decision ENUM('Approved', 'Rejected') NOT NULL,
    decision_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    comments TEXT,
    FOREIGN KEY (booking_id) REFERENCES BOOKING(booking_id),
    FOREIGN KEY (approver_id) REFERENCES `USER`(user_id)
);

CREATE TABLE MAINTENANCE (
    maintenance_id INT PRIMARY KEY AUTO_INCREMENT,
    resource_id INT NOT NULL,
    reported_by INT,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME,
    issue_description TEXT NOT NULL,
    status ENUM('Scheduled', 'In Progress', 'Completed', 'Cancelled') DEFAULT 'Scheduled',
    cost DECIMAL(10,2),
    FOREIGN KEY (resource_id) REFERENCES RESOURCE(resource_id),
    FOREIGN KEY (reported_by) REFERENCES `USER`(user_id)
);

CREATE TABLE USAGE_LOG (
    usage_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL,
    resource_id INT NOT NULL,
    check_in DATETIME,
    check_out DATETIME,
    actual_user_id INT,
    remarks TEXT,
    FOREIGN KEY (booking_id) REFERENCES BOOKING(booking_id),
    FOREIGN KEY (resource_id) REFERENCES RESOURCE(resource_id),
    FOREIGN KEY (actual_user_id) REFERENCES `USER`(user_id)
);

CREATE TABLE CANCELLATION (
    cancellation_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL UNIQUE,
    cancelled_by INT NOT NULL,
    cancellation_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    FOREIGN KEY (booking_id) REFERENCES BOOKING(booking_id),
    FOREIGN KEY (cancelled_by) REFERENCES `USER`(user_id)
);

CREATE TABLE AUDIT_LOG (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50),
    operation VARCHAR(20),
    record_id INT,
    old_value TEXT,
    new_value TEXT,
    changed_by INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (changed_by) REFERENCES `USER`(user_id)
);

-- ============================================================
-- 2. INDEXES
-- ============================================================

CREATE INDEX idx_booking_datetime ON BOOKING(start_datetime, end_datetime);
CREATE INDEX idx_booking_status ON BOOKING(status);
CREATE INDEX idx_resource_status ON RESOURCE(status);
CREATE INDEX idx_usage_booking ON USAGE_LOG(booking_id);
CREATE INDEX idx_user_role ON `USER`(role_id);
CREATE INDEX idx_booking_user ON BOOKING(user_id);

-- ============================================================
-- 3. SAMPLE DATA
-- ============================================================

INSERT INTO ROLE (role_name, description) VALUES
('Student', 'Can request bookings'),
('Faculty', 'Can request and approve within dept'),
('Lab Coordinator', 'Manages lab resources and approvals'),
('Department Admin', 'Full dept level control'),
('Maintenance Staff', 'Handles maintenance tickets'),
('Management', 'Analytics and reports only');

INSERT INTO DEPARTMENT (dept_code, dept_name, building, contact_email) VALUES
('CSE', 'Computer Science & Engineering', 'Block A', 'cse@univ.edu'),
('ECE', 'Electronics & Communication', 'Block B', 'ece@univ.edu'),
('ME', 'Mechanical Engineering', 'Block C', 'me@univ.edu'),
('EEE', 'Electrical Engineering', 'Block D', 'eee@univ.edu'),
('CIVIL', 'Civil Engineering', 'Block E', 'civil@univ.edu');

INSERT INTO `USER` (username, password_hash, email, full_name, phone, role_id, dept_id) VALUES
('admin_cse', 'hash1', 'admin.cse@univ.edu', 'Dr. Ananya Sharma', '9876543210', 4, 1),
('coord_lab', 'hash2', 'lab.coord@univ.edu', 'Prof. Rajesh Kumar', '9876543211', 3, 1),
('faculty1', 'hash3', 'faculty1@univ.edu', 'Dr. Priya Patel', '9876543212', 2, 1),
('faculty2', 'hash4', 'faculty2@univ.edu', 'Dr. Vikram Singh', '9876543213', 2, 2),
('student1', 'hash5', 'student1@univ.edu', 'Aarav Mehta', '9876543214', 1, 1),
('student2', 'hash6', 'student2@univ.edu', 'Sneha Reddy', '9876543215', 1, 1),
('student3', 'hash7', 'student3@univ.edu', 'Rohan Gupta', '9876543216', 1, 2),
('maint1', 'hash8', 'maint1@univ.edu', 'Suresh Nair', '9876543217', 5, NULL),
('mgmt1', 'hash9', 'mgmt@univ.edu', 'Dean Academics', '9876543218', 6, NULL),
('student4', 'hash10', 'student4@univ.edu', 'Neha Joshi', '9876543219', 1, 1);

-- Extra students
INSERT INTO `USER` (username, password_hash, email, full_name, role_id, dept_id)
SELECT CONCAT('student', n), CONCAT('hash', n+10), CONCAT('student', n, '@univ.edu'),
       CONCAT('Student ', n), 1, (n % 5) + 1
FROM (
    SELECT 11 AS n UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
    UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
    UNION SELECT 21 UNION SELECT 22 UNION SELECT 23 UNION SELECT 24 UNION SELECT 25
    UNION SELECT 26 UNION SELECT 27 UNION SELECT 28 UNION SELECT 29 UNION SELECT 30
) t;

INSERT INTO LOCATION (location_code, location_name, building, floor, capacity, location_type, dept_id) VALUES
('LAB-305', 'Advanced Computing Lab', 'Block A', 3, 40, 'Lab', 1),
('LAB-201', 'Programming Lab', 'Block A', 2, 60, 'Lab', 1),
('SH-101', 'Seminar Hall 1', 'Block A', 1, 150, 'Seminar Hall', 1),
('SC-401', 'Smart Classroom 401', 'Block B', 4, 80, 'Smart Classroom', 2),
('LAB-ECE1', 'VLSI Lab', 'Block B', 2, 30, 'Lab', 2),
('WS-ME1', 'CAD Workshop', 'Block C', 1, 25, 'Workshop', 3),
('LAB-EEE1', 'Power Systems Lab', 'Block D', 3, 35, 'Lab', 4),
('SH-201', 'Seminar Hall 2', 'Block A', 2, 100, 'Seminar Hall', NULL);

INSERT INTO RESOURCE_TYPE (type_name, description) VALUES
('Computer System', 'Desktop / Workstation'),
('Projector', 'Multimedia Projector'),
('IoT Kit', 'Arduino / Raspberry Pi kits'),
('3D Printer', 'Additive manufacturing'),
('Network Equipment', 'Switches, routers, etc.'),
('Research Equipment', 'Specialized instruments'),
('Furniture', 'Tables, chairs for events');

INSERT INTO RESOURCE (resource_code, resource_name, type_id, location_id, status, purchase_date) VALUES
('PC-LAB305-01', 'Dell Workstation 01', 1, 1, 'Available', '2023-01-15'),
('PC-LAB305-02', 'Dell Workstation 02', 1, 1, 'Available', '2023-01-15'),
('PC-LAB305-03', 'Dell Workstation 03', 1, 1, 'Available', '2023-01-15'),
('PROJ-SH101', 'Epson Projector SH101', 2, 3, 'Available', '2022-06-10'),
('IOT-KIT-01', 'Arduino Starter Kit 01', 3, 1, 'Available', '2024-02-01'),
('IOT-KIT-02', 'Raspberry Pi Kit 02', 3, 1, 'Available', '2024-02-01'),
('3DP-01', 'Ultimaker 3D Printer', 4, 1, 'Available', '2023-09-20'),
('SW-LAB201-01', 'Cisco Switch', 5, 2, 'Available', '2022-11-05'),
('PC-LAB201-01', 'HP Desktop 01', 1, 2, 'Available', '2023-03-12'),
('PC-LAB201-02', 'HP Desktop 02', 1, 2, 'Available', '2023-03-12'),
('PROJ-SC401', 'BenQ Smart Projector', 2, 4, 'Available', '2023-07-18'),
('PC-ECE1-01', 'Workstation ECE', 1, 5, 'Under Maintenance', '2022-08-30');

-- Extra PCs
INSERT INTO RESOURCE (resource_code, resource_name, type_id, location_id, status)
SELECT CONCAT('PC-LAB305-', LPAD(n, 2, '0')), CONCAT('Dell Workstation ', n), 1, 1, 'Available'
FROM (
    SELECT 4 AS n UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 
    UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
) t;

INSERT INTO BOOKING (booking_code, user_id, purpose, start_datetime, end_datetime, status) VALUES
('BK20241001', 5, 'Mini Project Work - IoT', '2024-10-05 10:00:00', '2024-10-05 12:00:00', 'Approved'),
('BK20241002', 6, 'Lab Session - DBMS', '2024-10-05 14:00:00', '2024-10-05 16:00:00', 'Approved'),
('BK20241003', 3, 'Guest Lecture', '2024-10-06 11:00:00', '2024-10-06 13:00:00', 'Approved'),
('BK20241004', 5, '3D Printing Prototype', '2024-10-07 09:00:00', '2024-10-07 11:00:00', 'Pending'),
('BK20241005', 7, 'Project Demo', '2024-10-08 15:00:00', '2024-10-08 17:00:00', 'Approved'),
('BK20241006', 11, 'Self Study', '2024-10-09 10:00:00', '2024-10-09 12:00:00', 'Cancelled'),
('BK20241007', 12, 'Research Work', '2024-10-10 13:00:00', '2024-10-10 16:00:00', 'Approved');

INSERT INTO BOOKING_ITEM (booking_id, resource_id, quantity) VALUES
(1, 5, 1),
(1, 1, 1),
(2, 9, 1),
(3, 4, 1),
(4, 7, 1),
(5, 11, 1),
(7, 1, 2),
(7, 2, 1);

INSERT INTO APPROVAL (booking_id, approver_id, decision, comments) VALUES
(1, 2, 'Approved', 'Approved for project work'),
(2, 2, 'Approved', 'Regular lab session'),
(3, 1, 'Approved', 'Guest lecture confirmed'),
(5, 2, 'Approved', 'OK'),
(7, 2, 'Approved', 'Research approved');

INSERT INTO MAINTENANCE (resource_id, reported_by, start_datetime, end_datetime, issue_description, status, cost) VALUES
(12, 8, '2024-09-20 09:00:00', '2024-09-25 17:00:00', 'Hard disk failure', 'Completed', 4500.00),
(7, 8, '2024-10-01 10:00:00', NULL, 'Nozzle clogging', 'In Progress', NULL);

INSERT INTO USAGE_LOG (booking_id, resource_id, check_in, check_out, actual_user_id) VALUES
(1, 5, '2024-10-05 10:05:00', '2024-10-05 11:50:00', 5),
(1, 1, '2024-10-05 10:05:00', '2024-10-05 11:55:00', 5),
(2, 9, '2024-10-05 14:02:00', '2024-10-05 15:58:00', 6);

INSERT INTO CANCELLATION (booking_id, cancelled_by, reason) VALUES
(6, 11, 'Clash with exam');

-- ============================================================
-- 4. VIEWS
-- ============================================================

CREATE OR REPLACE VIEW vw_current_availability AS
SELECT 
    r.resource_id,
    r.resource_code,
    r.resource_name,
    rt.type_name,
    l.location_code,
    l.location_name,
    r.status
FROM RESOURCE r
JOIN RESOURCE_TYPE rt ON r.type_id = rt.type_id
JOIN LOCATION l ON r.location_id = l.location_id
WHERE r.status = 'Available'
  AND r.resource_id NOT IN (
      SELECT bi.resource_id
      FROM BOOKING_ITEM bi
      JOIN BOOKING b ON bi.booking_id = b.booking_id
      WHERE b.status IN ('Approved', 'Pending')
        AND NOW() BETWEEN b.start_datetime AND b.end_datetime
  );

CREATE OR REPLACE VIEW vw_pending_bookings AS
SELECT 
    b.booking_code, 
    u.full_name, 
    b.purpose, 
    b.start_datetime, 
    b.end_datetime
FROM BOOKING b
JOIN `USER` u ON b.user_id = u.user_id
WHERE b.status = 'Pending';

-- ============================================================
-- 5. STORED PROCEDURES
-- ============================================================

DELIMITER //

CREATE PROCEDURE sp_create_booking(
    IN p_user_id INT,
    IN p_purpose VARCHAR(255),
    IN p_start DATETIME,
    IN p_end DATETIME,
    OUT p_booking_id INT,
    OUT p_message VARCHAR(200)
)
BEGIN
    DECLARE v_user_count INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Error occurred. Transaction rolled back.';
        SET p_booking_id = NULL;
    END;

    SET p_booking_id = NULL;
    SET p_message = NULL;

    IF p_purpose IS NULL OR TRIM(p_purpose) = '' THEN
        SET p_message = 'Purpose is required.';
    ELSEIF p_start IS NULL OR p_end IS NULL OR p_end <= p_start THEN
        SET p_message = 'End time must be later than start time.';
    ELSE
        SELECT COUNT(*) INTO v_user_count
        FROM `USER`
        WHERE user_id = p_user_id AND is_active = TRUE;

        IF v_user_count = 0 THEN
            SET p_message = 'User does not exist or is inactive.';
        ELSE
            START TRANSACTION;

            INSERT INTO BOOKING
                (booking_code, user_id, purpose, start_datetime, end_datetime, status)
            VALUES
                (
                    CONCAT('BK', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'),
                           LPAD(FLOOR(RAND() * 1000), 3, '0')),
                    p_user_id, p_purpose, p_start, p_end, 'Pending'
                );

            SET p_booking_id = LAST_INSERT_ID();
            SET p_message = 'Booking created successfully. Pending approval.';
            COMMIT;
        END IF;
    END IF;
END //

CREATE PROCEDURE sp_process_approval(
    IN p_booking_id INT,
    IN p_approver_id INT,
    IN p_decision VARCHAR(20),
    IN p_comments TEXT,
    OUT p_message VARCHAR(200)
)
BEGIN
    DECLARE v_status VARCHAR(20) DEFAULT NULL;
    DECLARE v_booking_count INT DEFAULT 0;
    DECLARE v_approver_count INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Error during approval. Transaction rolled back.';
    END;

    IF p_decision IS NULL OR p_decision NOT IN ('Approved', 'Rejected') THEN
        SET p_message = 'Decision must be Approved or Rejected.';
    ELSE
        START TRANSACTION;

        SELECT COUNT(*) INTO v_booking_count
        FROM BOOKING
        WHERE booking_id = p_booking_id;

        SELECT COUNT(*) INTO v_approver_count
        FROM `USER`
        WHERE user_id = p_approver_id AND is_active = TRUE;

        IF v_booking_count = 0 THEN
            SET p_message = 'Booking does not exist.';
            ROLLBACK;
        ELSEIF v_approver_count = 0 THEN
            SET p_message = 'Approver does not exist or is inactive.';
            ROLLBACK;
        ELSE
            SELECT status INTO v_status
            FROM BOOKING
            WHERE booking_id = p_booking_id
            FOR UPDATE;

            IF v_status <> 'Pending' THEN
                SET p_message = 'Booking is not in Pending state.';
                ROLLBACK;
            ELSE
                UPDATE BOOKING
                SET status = p_decision
                WHERE booking_id = p_booking_id;

                INSERT INTO APPROVAL
                    (booking_id, approver_id, decision, comments)
                VALUES
                    (p_booking_id, p_approver_id, p_decision, p_comments);

                SET p_message = CONCAT('Booking ', p_decision, ' successfully.');
                COMMIT;
            END IF;
        END IF;
    END IF;
END //

DELIMITER ;

-- ============================================================
-- 6. FUNCTION
-- ============================================================

DELIMITER //

CREATE FUNCTION fn_resource_utilization(
    p_resource_id INT,
    p_from_date DATE,
    p_to_date DATE
) RETURNS DECIMAL(7,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total_hours DECIMAL(10,2) DEFAULT 0;
    DECLARE booked_hours DECIMAL(10,2) DEFAULT 0;

    IF p_from_date IS NULL OR p_to_date IS NULL OR p_to_date < p_from_date THEN
        RETURN 0;
    END IF;

    -- Assumption: one resource is available for 8 working hours per calendar day.
    SET total_hours = (DATEDIFF(p_to_date, p_from_date) + 1) * 8;

    SELECT IFNULL(
        SUM(
            TIMESTAMPDIFF(
                MINUTE,
                GREATEST(b.start_datetime, CAST(p_from_date AS DATETIME)),
                LEAST(b.end_datetime, CAST(DATE_ADD(p_to_date, INTERVAL 1 DAY) AS DATETIME))
            )
        ) / 60,
        0
    )
    INTO booked_hours
    FROM BOOKING b
    JOIN BOOKING_ITEM bi ON b.booking_id = bi.booking_id
    WHERE bi.resource_id = p_resource_id
      AND b.status = 'Approved'
      AND b.start_datetime < DATE_ADD(p_to_date, INTERVAL 1 DAY)
      AND b.end_datetime > CAST(p_from_date AS DATETIME);

    IF total_hours <= 0 THEN
        RETURN 0;
    END IF;

    RETURN ROUND((booked_hours / total_hours) * 100, 2);
END //

DELIMITER ;

-- ============================================================
-- 7. TRIGGERS
-- ============================================================

DELIMITER //

-- Prevent overlapping bookings
CREATE TRIGGER trg_prevent_overlap
BEFORE INSERT ON BOOKING_ITEM
FOR EACH ROW
BEGIN
    DECLARE v_conflict INT DEFAULT 0;
    DECLARE v_start DATETIME;
    DECLARE v_end DATETIME;
    DECLARE v_status VARCHAR(20);

    SELECT start_datetime, end_datetime, status
    INTO v_start, v_end, v_status
    FROM BOOKING 
    WHERE booking_id = NEW.booking_id;

    IF v_status IN ('Approved', 'Pending') THEN
        SELECT COUNT(*) INTO v_conflict
        FROM BOOKING_ITEM bi
        JOIN BOOKING b ON bi.booking_id = b.booking_id
        WHERE bi.resource_id = NEW.resource_id
          AND b.booking_id != NEW.booking_id
          AND b.status IN ('Approved', 'Pending')
          AND v_start < b.end_datetime 
          AND v_end > b.start_datetime;

        IF v_conflict > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Overlap detected: Resource already booked in this time slot.';
        END IF;
    END IF;
END //

-- Prevent overlapping bookings when an existing booking's time is changed.
CREATE TRIGGER trg_prevent_overlap_update
BEFORE UPDATE ON BOOKING
FOR EACH ROW
BEGIN
    DECLARE v_conflict INT DEFAULT 0;

    IF NEW.start_datetime IS NULL OR NEW.end_datetime IS NULL
       OR NEW.end_datetime <= NEW.start_datetime THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid booking interval.';
    END IF;

    IF NEW.status IN ('Approved', 'Pending') THEN
        SELECT COUNT(*) INTO v_conflict
        FROM BOOKING_ITEM bi1
        JOIN BOOKING_ITEM bi2 ON bi1.resource_id = bi2.resource_id
        JOIN BOOKING b2 ON b2.booking_id = bi2.booking_id
        WHERE bi1.booking_id = NEW.booking_id
          AND bi2.booking_id <> NEW.booking_id
          AND b2.status IN ('Approved', 'Pending')
          AND NEW.start_datetime < b2.end_datetime
          AND NEW.end_datetime > b2.start_datetime;

        IF v_conflict > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Overlap detected: Resource already booked in this time slot.';
        END IF;
    END IF;
END //

-- Audit log on status change
CREATE TRIGGER trg_audit_booking_status
AFTER UPDATE ON BOOKING
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_value, new_value, changed_by)
        VALUES ('BOOKING', 'STATUS_CHANGE', NEW.booking_id, OLD.status, NEW.status, NULL);
    END IF;
END //

-- Auto update resource status on maintenance
CREATE TRIGGER trg_maintenance_status
AFTER INSERT ON MAINTENANCE
FOR EACH ROW
BEGIN
    IF NEW.status IN ('Scheduled', 'In Progress') THEN
        UPDATE RESOURCE 
        SET status = 'Under Maintenance' 
        WHERE resource_id = NEW.resource_id;
    END IF;
END //

-- Re-check the resource after a maintenance record changes.
-- Mark it Available only when no other active maintenance remains.
CREATE TRIGGER trg_maintenance_status_update
AFTER UPDATE ON MAINTENANCE
FOR EACH ROW
BEGIN
    IF NEW.status IN ('Scheduled', 'In Progress') THEN
        UPDATE RESOURCE
        SET status = 'Under Maintenance'
        WHERE resource_id = NEW.resource_id;
    ELSEIF NEW.status IN ('Completed', 'Cancelled') THEN
        IF NOT EXISTS (
            SELECT 1
            FROM MAINTENANCE m
            WHERE m.resource_id = NEW.resource_id
              AND m.maintenance_id <> NEW.maintenance_id
              AND m.status IN ('Scheduled', 'In Progress')
        ) THEN
            UPDATE RESOURCE
            SET status = 'Available'
            WHERE resource_id = NEW.resource_id
              AND status = 'Under Maintenance';
        END IF;
    END IF;
END //

DELIMITER ;

-- ============================================================
-- 8. COMPLEX QUERIES (MySQL 8.4 compatible)
-- ============================================================

-- Q1: Find resources available in a time interval
-- Change the two datetime values to the interval you want to check.
SELECT
    r.resource_id,
    r.resource_code,
    r.resource_name,
    l.location_name
FROM RESOURCE r
JOIN LOCATION l
    ON r.location_id = l.location_id
WHERE r.status = 'Available'
  AND NOT EXISTS (
      SELECT 1
      FROM BOOKING_ITEM bi
      JOIN BOOKING b
          ON bi.booking_id = b.booking_id
      WHERE bi.resource_id = r.resource_id
        AND b.status IN ('Approved', 'Pending')
        AND '2026-11-05 10:00:00' < b.end_datetime
        AND '2026-11-05 12:00:00' > b.start_datetime
  );

-- Q2: Detect overlapping bookings for the same resource
SELECT
    b1.booking_code AS booking1,
    b2.booking_code AS booking2,
    bi1.resource_id,
    b1.start_datetime AS booking1_start,
    b1.end_datetime AS booking1_end,
    b2.start_datetime AS booking2_start,
    b2.end_datetime AS booking2_end
FROM BOOKING b1
JOIN BOOKING_ITEM bi1
    ON b1.booking_id = bi1.booking_id
JOIN BOOKING_ITEM bi2
    ON bi1.resource_id = bi2.resource_id
   AND bi1.booking_id < bi2.booking_id
JOIN BOOKING b2
    ON bi2.booking_id = b2.booking_id
WHERE b1.status IN ('Approved', 'Pending')
  AND b2.status IN ('Approved', 'Pending')
  AND b1.start_datetime < b2.end_datetime
  AND b1.end_datetime > b2.start_datetime;

-- Q3: Rank resources by utilization
SELECT
    resource_code,
    booked_hours,
    RANK() OVER (ORDER BY booked_hours DESC) AS util_rank,
    DENSE_RANK() OVER (ORDER BY booked_hours DESC) AS dense_rank_position
FROM (
    SELECT
        r.resource_id,
        r.resource_code,
        IFNULL(
            SUM(TIMESTAMPDIFF(MINUTE, b.start_datetime, b.end_datetime)) / 60,
            0
        ) AS booked_hours
    FROM RESOURCE r
    LEFT JOIN BOOKING_ITEM bi
        ON r.resource_id = bi.resource_id
    LEFT JOIN BOOKING b
        ON bi.booking_id = b.booking_id
       AND b.status = 'Approved'
    GROUP BY r.resource_id, r.resource_code
) AS util
ORDER BY util_rank;

-- Q4: Departments above the institutional average utilization
SELECT
    d.dept_id,
    d.dept_name,
    SUM(
        TIMESTAMPDIFF(MINUTE, b.start_datetime, b.end_datetime)
    ) / 60 AS hours
FROM DEPARTMENT d
JOIN LOCATION l
    ON d.dept_id = l.dept_id
JOIN RESOURCE r
    ON l.location_id = r.location_id
JOIN BOOKING_ITEM bi
    ON r.resource_id = bi.resource_id
JOIN BOOKING b
    ON bi.booking_id = b.booking_id
WHERE b.status = 'Approved'
GROUP BY d.dept_id, d.dept_name
HAVING hours > (
    SELECT AVG(dept_hours)
    FROM (
        SELECT
            d2.dept_id,
            SUM(
                TIMESTAMPDIFF(
                    MINUTE,
                    b2.start_datetime,
                    b2.end_datetime
                )
            ) / 60 AS dept_hours
        FROM DEPARTMENT d2
        JOIN LOCATION l2
            ON d2.dept_id = l2.dept_id
        JOIN RESOURCE r2
            ON l2.location_id = r2.location_id
        JOIN BOOKING_ITEM bi2
            ON r2.resource_id = bi2.resource_id
        JOIN BOOKING b2
            ON bi2.booking_id = b2.booking_id
        WHERE b2.status = 'Approved'
        GROUP BY d2.dept_id
    ) AS dept_average
);

-- Q5: Monthly resource utilization
SELECT
    r.resource_code,
    DATE_FORMAT(b.start_datetime, '%Y-%m') AS month,
    SUM(
        TIMESTAMPDIFF(MINUTE, b.start_datetime, b.end_datetime)
    ) / 60 AS hours
FROM RESOURCE r
JOIN BOOKING_ITEM bi
    ON r.resource_id = bi.resource_id
JOIN BOOKING b
    ON bi.booking_id = b.booking_id
WHERE b.status = 'Approved'
GROUP BY
    r.resource_id,
    r.resource_code,
    DATE_FORMAT(b.start_datetime, '%Y-%m')
ORDER BY month, hours DESC;

-- Q6: Resources used by Pending bookings but not by any Approved booking
-- MySQL does not support EXCEPT; NOT EXISTS provides the equivalent result.
SELECT DISTINCT
    bi.resource_id
FROM BOOKING_ITEM bi
JOIN BOOKING b
    ON bi.booking_id = b.booking_id
WHERE b.status = 'Pending'
  AND NOT EXISTS (
      SELECT 1
      FROM BOOKING_ITEM bi2
      JOIN BOOKING b2
          ON bi2.booking_id = b2.booking_id
      WHERE bi2.resource_id = bi.resource_id
        AND b2.status = 'Approved'
  );

-- ============================================================
-- END OF SCRIPT
-- ============================================================

SELECT 'Script executed successfully!' AS message;
SHOW TABLES;
