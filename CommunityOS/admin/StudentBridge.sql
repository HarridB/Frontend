-- StudentBridge.sql
-- SQLite-friendly SQL script for CommunityOS
-- This script creates tables for signup/login, announcements, jobs, hostels,
-- and a unified view that can return data for the entire CommunityOS app.

BEGIN;

DROP TABLE IF EXISTS hostel_bookings;
DROP TABLE IF EXISTS hostel_pictures;
DROP TABLE IF EXISTS job_applications;
DROP TABLE IF EXISTS job_requirements;
DROP TABLE IF EXISTS hostels;
DROP TABLE IF EXISTS jobs;
DROP TABLE IF EXISTS announcements;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email_phone TEXT NOT NULL,
    institution_name TEXT NOT NULL,
    faculty TEXT NOT NULL,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('student', 'admin', 'hostel_manager', 'marketplace_manager')),
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE announcements (
    announcement_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    audience TEXT NOT NULL,
    created_by INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY(created_by) REFERENCES users(user_id)
);

CREATE TABLE jobs (
    job_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    company TEXT NOT NULL,
    location TEXT NOT NULL,
    job_type TEXT NOT NULL CHECK(job_type IN ('Remote', 'Office', 'Hybrid')),
    description TEXT NOT NULL,
    created_by INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY(created_by) REFERENCES users(user_id)
);

CREATE TABLE job_requirements (
    requirement_id INTEGER PRIMARY KEY AUTOINCREMENT,
    job_id INTEGER NOT NULL,
    requirement TEXT NOT NULL,
    FOREIGN KEY(job_id) REFERENCES jobs(job_id) ON DELETE CASCADE
);

CREATE TABLE job_applications (
    application_id INTEGER PRIMARY KEY AUTOINCREMENT,
    job_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    applicant_name TEXT NOT NULL,
    application_status TEXT NOT NULL DEFAULT 'Pending',
    applied_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY(job_id) REFERENCES jobs(job_id) ON DELETE CASCADE,
    FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE hostels (
    hostel_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    amount REAL NOT NULL,
    currency TEXT NOT NULL,
    created_by INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY(created_by) REFERENCES users(user_id)
);

CREATE TABLE hostel_pictures (
    picture_id INTEGER PRIMARY KEY AUTOINCREMENT,
    hostel_id INTEGER NOT NULL,
    picture_url TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY(hostel_id) REFERENCES hostels(hostel_id) ON DELETE CASCADE
);

CREATE TABLE hostel_bookings (
    booking_id INTEGER PRIMARY KEY AUTOINCREMENT,
    hostel_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    booking_status TEXT NOT NULL DEFAULT 'Booked',
    booked_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY(hostel_id) REFERENCES hostels(hostel_id) ON DELETE CASCADE,
    FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE VIEW vw_users AS
SELECT
    user_id,
    first_name,
    last_name,
    email_phone,
    institution_name,
    faculty,
    username,
    role,
    created_at
FROM users;

CREATE VIEW vw_announcements AS
SELECT
    a.announcement_id,
    a.title,
    a.message,
    a.audience,
    u.username AS published_by,
    a.created_at
FROM announcements a
LEFT JOIN users u ON u.user_id = a.created_by;

CREATE VIEW vw_jobs AS
SELECT
    j.job_id,
    j.title,
    j.company,
    j.location,
    j.job_type,
    j.description,
    u.username AS posted_by,
    j.created_at,
    (
        SELECT GROUP_CONCAT(r.requirement, ' || ')
        FROM job_requirements r
        WHERE r.job_id = j.job_id
    ) AS requirements
FROM jobs j
LEFT JOIN users u ON u.user_id = j.created_by;

CREATE VIEW vw_hostels AS
SELECT
    h.hostel_id,
    h.name,
    h.description,
    h.amount,
    h.currency,
    u.username AS posted_by,
    h.created_at,
    (
        SELECT GROUP_CONCAT(p.picture_url, ' || ')
        FROM hostel_pictures p
        WHERE p.hostel_id = h.hostel_id
    ) AS pictures
FROM hostels h
LEFT JOIN users u ON u.user_id = h.created_by;

CREATE VIEW vw_communityos_dashboard AS
SELECT 'users' AS section, user_id AS record_id, username, role, created_at, NULL AS title, NULL AS company, NULL AS location
FROM users

UNION ALL

SELECT 'announcements' AS section, announcement_id AS record_id, published_by AS username, audience AS role, created_at, title, NULL AS company, NULL AS location
FROM vw_announcements

UNION ALL

SELECT 'jobs' AS section, job_id AS record_id, posted_by AS username, job_type AS role, created_at, title, company, location
FROM vw_jobs

UNION ALL

SELECT 'hostels' AS section, hostel_id AS record_id, posted_by AS username, currency AS role, created_at, name AS title, NULL AS company, NULL AS location
FROM vw_hostels;

INSERT INTO users (
    first_name,
    last_name,
    email_phone,
    institution_name,
    faculty,
    username,
    password_hash,
    role
) VALUES
('Student', 'Bridge', 'student@campus.com', 'University of Lagos', 'Computer Science', 'student01', 'student123', 'student'),
('Admin', 'Bridge', 'admin@campus.com', 'University of Lagos', 'Administration', 'admin01', 'admin123', 'admin'),
('Hostel', 'Manager', 'hostel@campus.com', 'University of Lagos', 'Accommodation', 'hostel01', 'hostel123', 'hostel_manager'),
('Marketplace', 'Manager', 'market@campus.com', 'University of Lagos', 'Business', 'market01', 'market123', 'marketplace_manager');

INSERT INTO announcements (title, message, audience, created_by) VALUES
('Welcome Week', 'Welcome to Student Bridge. Log in to see announcements, jobs, and hostel updates.', 'All Students', 1),
('Job Fair', 'A job fair will take place on Saturday. Students should come prepared with CVs.', 'All Students', 2),
('Hostel Update', 'New hostel rooms have been added for the new session.', 'Students', 3);

INSERT INTO jobs (title, company, location, job_type, description, created_by) VALUES
('Remote Frontend Developer Intern', 'Nova Studio', 'Remote', 'Remote', 'Build responsive web interfaces and support student-focused digital products.', 2),
('Office Administrative Assistant', 'BrightPath Learning', 'Lagos', 'Office', 'Support office operations, schedule management, and student outreach.', 2),
('Hybrid Data Entry Officer', 'ConnectCare Partners', 'Abuja', 'Hybrid', 'Update records and support reporting while working from home and office.', 2);

INSERT INTO job_requirements (job_id, requirement) VALUES
(1, 'HTML, CSS and JavaScript'),
(1, 'Responsive design knowledge'),
(1, 'Strong teamwork skills'),
(2, 'Good communication skills'),
(2, 'Office productivity tools'),
(3, 'Fast typing accuracy'),
(3, 'Spreadsheet skills'),
(3, 'Attention to detail');

INSERT INTO hostels (name, description, amount, currency, created_by) VALUES
('Skyline Hostel', 'Comfortable shared hostel near the school gate with Wi-Fi and security.', 450000, 'NGN', 3),
('Greenview Residence', 'Modern student residence with clean rooms and study spaces.', 550000, 'NGN', 3);

INSERT INTO hostel_pictures (hostel_id, picture_url) VALUES
(1, 'images/hostel-one.jpg'),
(1, 'images/hostel-two.jpg'),
(2, 'images/hostel-three.jpg');

COMMIT;

-- Example signup query:
-- INSERT INTO users (
--     first_name,
--     last_name,
--     email_phone,
--     institution_name,
--     faculty,
--     username,
--     password_hash,
--     role
-- ) VALUES (
--     'Ada',
--     'Smith',
--     'ada@example.com',
--     'University of Lagos',
--     'Computer Science',
--     'ada01',
--     'securePassword123',
--     'student'
-- );

-- Example login query:
-- SELECT user_id, first_name, last_name, username, role
-- FROM users
-- WHERE username = 'student01'
--   AND password_hash = 'student123';

-- Return all CommunityOS data:
-- SELECT * FROM vw_communityos_dashboard;

-- Return all users:
-- SELECT * FROM vw_users;

-- Return all announcements:
-- SELECT * FROM vw_announcements;

-- Return all jobs with requirements:
-- SELECT * FROM vw_jobs;

-- Return all hostels with pictures:
-- SELECT * FROM vw_hostels;