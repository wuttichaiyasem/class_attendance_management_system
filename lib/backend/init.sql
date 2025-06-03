CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL
);

CREATE TABLE user_roles (
    user_id VARCHAR(50) NOT NULL,
    role ENUM('subject', 'homeroom') NOT NULL,
    PRIMARY KEY (user_id, role),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE students (
    student_id VARCHAR(50) PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT,
    class_year INTEGER NOT NULL,
    group_number INTEGER NOT NULL,
    homeroom_teacher_id VARCHAR(50),
    FOREIGN KEY (homeroom_teacher_id) REFERENCES users(user_id)
);

CREATE TABLE parents (
  student_id VARCHAR(50),
  line_id VARCHAR(100),
  PRIMARY KEY (student_id, line_id),
  FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE parent_notifications (
    student_id VARCHAR(50),
    notified_at DATETIME,
    reason TEXT, 
    PRIMARY KEY (student_id, reason(50)),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE subjects (
    subject_id VARCHAR(50) PRIMARY KEY,
    subject_name TEXT NOT NULL
);

CREATE TABLE classes (
    class_id VARCHAR(50) PRIMARY KEY,
    subject_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    class_year INTEGER NOT NULL,
    group_number INTEGER NOT NULL,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE class_sessions (
    session_id VARCHAR(50) PRIMARY KEY,
    class_id VARCHAR(50) NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,        -- eg. 'Tuesday'
    start_time TIME NOT NULL,                -- eg. '10:00:00'
    end_time TIME NOT NULL,                  -- eg. '12:00:00'
    start_date DATE NOT NULL,                -- eg. '2025-06-01'
    end_date DATE NOT NULL,                  -- eg. '2025-08-31'
    FOREIGN KEY (class_id) REFERENCES classes(class_id)
);

CREATE TABLE class_students (
    class_id VARCHAR(50),
    student_id VARCHAR(50),
    PRIMARY KEY (class_id, student_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE attendance_sessions (
    attendance_id VARCHAR(50) PRIMARY KEY,
    class_id VARCHAR(50) NOT NULL,
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_by VARCHAR(50),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id)
);

CREATE TABLE attendance_records (
    attendance_id VARCHAR(50),
    student_id VARCHAR(50),
    status VARCHAR(20) CHECK (status IN ('present', 'late', 'absent', 'personal_leave', 'sick_leave')) NOT NULL,
    marked_at DATETIME,
    PRIMARY KEY (attendance_id, student_id),
    FOREIGN KEY (attendance_id) REFERENCES attendance_sessions(attendance_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE homework (
    homework_id VARCHAR(50) PRIMARY KEY,
    class_id VARCHAR(50) NOT NULL,
    title TEXT NOT NULL,
    assign_date DATE NOT NULL,
    due_date DATE NOT NULL,
    FOREIGN KEY (class_id) REFERENCES classes(class_id)
);

CREATE TABLE homework_submissions (
    homework_id VARCHAR(50),
    student_id VARCHAR(50),
    status VARCHAR(20) CHECK (status IN ('submitted', 'late', 'missing')) NOT NULL DEFAULT 'missing',
    submitted_at DATETIME,
    PRIMARY KEY (homework_id, student_id),
    FOREIGN KEY (homework_id) REFERENCES homework(homework_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE tuition_status (
    student_id VARCHAR(50) PRIMARY KEY,
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    last_updated DATE,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);
