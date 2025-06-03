const express = require("express");
const router = express.Router();
const pool = require("../db");
const authMiddleware = require("../middleware/auth");

function getLocalDateString(date) {
  if (!(date instanceof Date)) {
    throw new Error("Invalid date object");
  }
  return date.toLocaleDateString("en-CA", { timeZone: "Asia/Bangkok" });
}

router.get("/", async (req, res) => {
  const { class_id, date, start_time, end_time } = req.query;

  if (!class_id || !date || !start_time || !end_time)
    return res.status(400).json({ error: "Missing parameters" });

  try {
    const conn = await pool.getConnection();

    const [sessionRows] = await conn.execute(
      `
      SELECT * FROM attendance_sessions 
      WHERE class_id = ? AND session_date = ? AND start_time = ? AND end_time = ?
    `,
      [class_id, date, start_time, end_time]
    );

    const attendanceSession = sessionRows[0];

    // ดึงนักเรียนทั้งหมดใน class นี้
    const [studentRows] = await conn.execute(
      `
      SELECT s.student_id, s.full_name
      FROM class_students cs
      JOIN students s ON cs.student_id = s.student_id
      WHERE cs.class_id = ?
    `,
      [class_id]
    );

    // ถ้ามี session แล้ว ดึงสถานะด้วย
    if (attendanceSession) {
      const [records] = await conn.execute(
        `
        SELECT student_id, status, marked_at
        FROM attendance_records
        WHERE attendance_id = ?
      `,
        [attendanceSession.attendance_id]
      );

      const recordsMap = Object.fromEntries(
        records.map((r) => [r.student_id, r])
      );

      const students = studentRows.map((s) => ({
        student_id: s.student_id,
        full_name: s.full_name,
        status: recordsMap[s.student_id]?.status || null,
        marked_at: recordsMap[s.student_id]?.marked_at || null,
      }));

      res.json({ attendance_id: attendanceSession.attendance_id, students });
    } else {
      res.json({
        attendance_id: null,
        students: studentRows.map((s) => ({
          student_id: s.student_id,
          full_name: s.full_name,
          status: null,
          marked_at: null,
        })),
      });
    }

    conn.release();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.post("/mark", async (req, res) => {
  const { class_id, date, start_time, end_time, created_by, records } =
    req.body;

  if (!class_id || !date || !start_time || !end_time || !created_by || !records)
    return res.status(400).json({ error: "Missing required fields" });

  let conn;

  try {
    conn = await pool.getConnection();

    const [sessionRows] = await conn.execute(
      `
      SELECT * FROM attendance_sessions 
      WHERE class_id = ? AND session_date = ? AND start_time = ? AND end_time = ?
    `,
      [class_id, date, start_time, end_time]
    );

    let attendance_id = sessionRows[0]?.attendance_id;

    if (!attendance_id) {
      attendance_id = `att_${Date.now()}`;
      await conn.execute(
        `
        INSERT INTO attendance_sessions (attendance_id, class_id, session_date, start_time, end_time, created_by)
        VALUES (?, ?, ?, ?, ?, ?)
      `,
        [attendance_id, class_id, date, start_time, end_time, created_by]
      );
    }

    for (const { student_id, status } of records) {
      await conn.execute(
        `
        INSERT INTO attendance_records (attendance_id, student_id, status, marked_at)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE status = ?, marked_at = NOW()
      `,
        [attendance_id, student_id, status, status]
      );
    }

    res.json({ message: "Attendance saved", attendance_id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (conn) conn.release();
  }
});

router.post("/check-absent", async (req, res) => {
  try {
    const conn = await pool.getConnection();

    const [activeSessions] = await conn.execute(
      `
      SELECT 
        attendance_id,
        class_id,
        session_date,
        start_time,
        end_time
      FROM attendance_sessions
      WHERE 
        (session_date < CURDATE()) OR
        (session_date = CURDATE() AND end_time < TIME_FORMAT(NOW(), '%H:%i'))
    `
    );

    for (const session of activeSessions) {
      await conn.execute(
        `
        INSERT INTO attendance_records (attendance_id, student_id, status, marked_at)
        SELECT 
          ?, 
          cs.student_id, 
          'absent',
          NOW()
        FROM class_students cs
        WHERE cs.class_id = ?
        AND NOT EXISTS (
          SELECT 1 
          FROM attendance_records ar 
          WHERE ar.attendance_id = ?
          AND ar.student_id = cs.student_id
        )
      `,
        [session.attendance_id, session.class_id, session.attendance_id]
      );
    }

    conn.release();
    res.json({ message: "Checked and marked absent for past sessions" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.get("/history", async (req, res) => {
  const { class_id, date, start_time, end_time } = req.query;

  if (!class_id || !date) {
    return res.status(400).json({ error: "class_id and date are required" });
  }

  try {
    const [sessionRows] = await pool.execute(
      `
      SELECT 
        a.attendance_id,
        a.class_id,
        a.session_date,
        a.start_time,
        a.end_time,
        sub.subject_name
      FROM attendance_sessions a
      JOIN classes c ON c.class_id = a.class_id
      JOIN subjects sub ON sub.subject_id = c.subject_id
      WHERE a.class_id = ?
        AND a.session_date = ?
        AND a.start_time = ?
        AND a.end_time = ?
      LIMIT 1
      `,
      [class_id, date, start_time, end_time]
    );

    if (sessionRows.length === 0) {
      return res.status(404).json({ error: "No attendance session found" });
    }

    const session = sessionRows[0];

    const [attendanceRecords] = await pool.execute(
      `
      SELECT
        s.student_id,
        s.full_name AS student_name,
        ar.status
      FROM attendance_records ar
      JOIN students s ON s.student_id = ar.student_id
      WHERE ar.attendance_id = ?
      ORDER BY s.student_id
      `,
      [session.attendance_id]
    );

    if (attendanceRecords.length === 0) {
      return res.status(404).json({ error: "No attendance records found" });
    }

    res.json({
      class_id: session.class_id,
      date: session.session_date,
      start_time: session.start_time,
      end_time: session.end_time,
      subject_name: session.subject_name,
      attendance: attendanceRecords.map((record) => ({
        student_id: record.student_id,
        name: record.student_name,
        status: record.status,
      })),
    });
  } catch (err) {
    console.error("Error fetching attendance history:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.get("/history-options", authMiddleware, async (req, res) => {
  const userId = req.user.user_id;

  if (!userId) {
    return res
      .status(401)
      .json({ error: "Unauthorized: Missing user_id in token" });
  }

  try {
    const [rows] = await pool.query(
      `
      SELECT 
        s.subject_name,
        a.session_date,
        TIME_FORMAT(a.start_time, '%H:%i') AS start_time,
        TIME_FORMAT(a.end_time, '%H:%i') AS end_time,
        a.class_id
      FROM attendance_sessions a
      JOIN classes c ON a.class_id = c.class_id
      JOIN subjects s ON c.subject_id = s.subject_id
      WHERE c.user_id = ?
      ORDER BY s.subject_name, a.session_date, a.start_time
      `,
      [userId]
    );

    const subjectMap = new Map();
    const subjectDates = {};
    const dateTimes = {};

    for (const row of rows) {
      const { subject_name, session_date, start_time, end_time, class_id } =
        row;

      const formattedDate = getLocalDateString(new Date(session_date));
      const timeLabel = `${start_time} - ${end_time}`;

      if (!subjectMap.has(subject_name)) {
        subjectMap.set(subject_name, class_id);
      }

      if (!subjectDates[subject_name]) {
        subjectDates[subject_name] = [];
      }
      if (!subjectDates[subject_name].includes(formattedDate)) {
        subjectDates[subject_name].push(formattedDate);
      }

      if (!dateTimes[formattedDate]) {
        dateTimes[formattedDate] = [];
      }
      if (
        !dateTimes[formattedDate].some(
          (t) => t.label === timeLabel && t.class_id === class_id
        )
      ) {
        dateTimes[formattedDate].push({
          label: timeLabel,
          start_time,
          end_time,
          class_id,
        });
      }
    }

    const subjects = [...subjectMap.entries()].map(([name, class_id]) => ({
      name,
      class_id,
    }));

    res.json({
      subjects,
      subjectDates,
      dateTimes,
    });
  } catch (err) {
    console.error("Error fetching history options:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
