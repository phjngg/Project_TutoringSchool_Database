CREATE TABLE users(
    "id" INTEGER,
    "email" TEXT NOT NULL UNIQUE,
    "role" TEXT NOT NULL CHECK("role" IN ('teacher', 'student')),
    "first_name" TEXT NOT NULL,
    "last_name" TEXT,
    "phone" TEXT,
    "parent_phone" TEXT,
    "is_active" INTEGER NOT NULL DEFAULT 1,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id")
);
CREATE TABLE courses (
    "id" INTEGER,
    "teacher_id" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "type" TEXT NOT NULL CHECK("type" IN ('onsite', 'recorded')),
    "total_sessions" INTEGER,
    "access_days" INTEGER,
    "price" INTEGER NOT NULL,
    "is_active" INTEGER NOT NULL DEFAULT 1,
    "enrolled_count" INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY("id"),
    FOREIGN KEY("teacher_id") REFERENCES "users"("id")
);
CREATE TABLE course_sessions (
    "id" INTEGER,
    "course_id" INTEGER NOT NULL,
    "session_date" DATE NOT NULL,
    "start_time" TIME NOT NULL,
    "end_time" TIME NOT NULL,
    "room_name" TEXT,
    "status" TEXT NOT NULL DEFAULT 'scheduled' CHECK(
        "status" IN ('scheduled', 'completed', 'cancelled')
    ),
    PRIMARY KEY("id"),
    FOREIGN KEY ("course_id") REFERENCES "courses"("id")
);
CREATE TABLE video_lessons (
    "id" INTEGER,
    "course_id" INTEGER NOT NULL,
    "topic" TEXT NOT NULL,
    "video_url" TEXT NOT NULL,
    "duration_minutes" INTEGER,
    "order_index" INTEGER NOT NULL,
    "is_active" INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY("id"),
    FOREIGN KEY ("course_id") REFERENCES "courses"("id")
);
CREATE TABLE enrollments (
    "id" INTEGER,
    "student_id" INTEGER NOT NULL,
    "course_id" INTEGER NOT NULL,
    "paid_price" INTEGER NOT NULL CHECK("paid_price" >= 0),
    "payment_status" TEXT NOT NULL DEFAULT 'pending' CHECK(
        "payment_status" IN ('paid', 'cancelled', 'pending')
    ),
    "status" TEXT NOT NULL DEFAULT 'active' CHECK("status" IN ('active', 'completed', 'cancelled')),
    "enrolled_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" DATETIME,
    PRIMARY KEY("id"),
    FOREIGN KEY("student_id") REFERENCES "users"("id"),
    FOREIGN KEY("course_id") REFERENCES "courses"("id")
);
CREATE TABLE payments (
    "id" INTEGER,
    "enrollment_id" INTEGER NOT NULL UNIQUE,
    "method" TEXT NOT NULL CHECK("method" IN ('cash', 'transfer')),
    "receipt_no" TEXT UNIQUE,
    "paid_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id"),
    FOREIGN KEY("enrollment_id") REFERENCES "enrollments"("id")
);
CREATE TRIGGER "set_expires_at"
AFTER
INSERT ON enrollments FOR EACH ROW BEGIN
UPDATE enrollments
SET expires_at = (
        SELECT CASE
                WHEN c.type = 'recorded' THEN datetime(NEW.enrolled_at, '+' || c.access_days || ' days')
                ELSE NULL
            END
        FROM courses c
        WHERE c.id = NEW.course_id
    )
WHERE id = NEW.id;
END;
CREATE TRIGGER "add_enrolled"
AFTER
INSERT ON enrollments FOR EACH ROW
    WHEN NEW.payment_status != 'cancelled' BEGIN
UPDATE courses
SET enrolled_count = enrolled_count + 1
WHERE id = NEW.course_id;
END;
CREATE TRIGGER "remove_enrolled"
AFTER
UPDATE ON enrollments FOR EACH ROW
    WHEN OLD.payment_status != 'cancelled'
    AND NEW.payment_status = 'cancelled' BEGIN
UPDATE courses
SET enrolled_count = enrolled_count - 1
WHERE id = NEW.course_id;
END;
CREATE INDEX "enrollments_student_idex" ON "enrollments"("student_id");
CREATE INDEX "enrollments_course_idex" ON "enrollments"("course_id");
CREATE INDEX "sessions_course_idex" ON "course_sessions"("course_id");
