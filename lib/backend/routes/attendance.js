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

  if (!class_id || !date || !start_time || !end_time) {
    return res.status(400).json({ error: "Missing parameters" });
  }

  try {
    const conn = await pool.getConnection();

    // 🔹 1. หา session_id จาก class_sessions
    const [sessionRows] = await conn.execute(
      `
      SELECT session_id
      FROM class_sessions
      WHERE class_id = ? 
        AND start_time = ? 
        AND end_time = ?
      LIMIT 1
      `,
      [class_id, start_time, end_time]
    );

    const session_id = sessionRows[0]?.session_id;

    // 🔹 2. ดึงนักเรียนจาก homeroom (แทน class_students)
    const [studentRows] = await conn.execute(
      `
      SELECT s.student_id, s.full_name
      FROM students s
      JOIN classes c ON s.homeroom_id = c.homeroom_id
      WHERE c.class_id = ?
      `,
      [class_id]
    );

    let recordsMap = {};
    let attendance_id = null;

    // 🔹 3. ถ้ามี session → ดึง attendance
    if (session_id) {
      const [records] = await conn.execute(
        `
        SELECT student_id, status, marked_at
        FROM attendance_records
        WHERE class_id = ?
          AND session_id = ?
          AND session_date = ?
        `,
        [class_id, session_id, date]
      );

      recordsMap = Object.fromEntries(
        records.map((r) => [r.student_id, r])
      );

      // 👉 fake attendance_id (ให้ frontend ใช้เหมือนเดิม)
      if (records.length > 0) {
        attendance_id = `${class_id}_${session_id}_${date}`;
      }
    }

    const students = studentRows.map((s) => ({
      student_id: s.student_id,
      full_name: s.full_name,
      status: recordsMap[s.student_id]?.status || null,
      marked_at: recordsMap[s.student_id]?.marked_at || null,
    }));

    res.json({
      attendance_id,
      students,
    });

    conn.release();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.post("/mark", async (req, res) => {
  const { class_id, date, start_time, end_time, records } = req.body;

  if (!class_id || !date || !start_time || !end_time || !records) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  let conn;

  try {
    conn = await pool.getConnection();

    // 🔹 1. หา session_id จาก class_sessions
    const [sessionRows] = await conn.execute(
      `
      SELECT session_id
      FROM class_sessions
      WHERE class_id = ? 
        AND start_time = ? 
        AND end_time = ?
      LIMIT 1
      `,
      [class_id, start_time, end_time]
    );

    const session_id = sessionRows[0]?.session_id;

    if (!session_id) {
      return res.status(400).json({ error: "Session not found" });
    }

    // 🔹 2. insert/update attendance
    for (const { student_id, status } of records) {
      await conn.execute(
        `
        INSERT INTO attendance_records
        (student_id, class_id, session_id, session_date, status, marked_at)
        VALUES (?, ?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE 
          status = VALUES(status),
          marked_at = NOW()
        `,
        [student_id, class_id, session_id, date, status]
      );
    }

    // 👉 fake attendance_id (keep frontend unchanged)
    const attendance_id = `${class_id}_${session_id}_${date}`;

    res.json({ message: "Attendance saved", attendance_id });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (conn) conn.release();
  }
});

router.post("/mark-present", async (req, res) => {
  const { class_id, date, start_time, end_time } = req.body;

  if (!class_id || !date || !start_time || !end_time) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  let conn;
  try {
    conn = await pool.getConnection();

    // 🔹 1. หา session_id จาก class_sessions
    const [sessionRows] = await conn.execute(
      `
      SELECT session_id
      FROM class_sessions
      WHERE class_id = ? 
        AND start_time = ? 
        AND end_time = ?
      LIMIT 1
      `,
      [class_id, start_time, end_time]
    );

    const session_id = sessionRows[0]?.session_id;

    if (!session_id) {
      return res.status(400).json({ error: "Session not found" });
    }

    // 🔹 2. mark present เฉพาะคนที่ยังไม่มี record
    await conn.execute(
      `
      INSERT INTO attendance_records 
      (student_id, class_id, session_id, session_date, status, marked_at)
      SELECT 
        s.student_id, ?, ?, ?, 'present', NOW()
      FROM students s
      JOIN classes c ON s.homeroom_id = c.homeroom_id
      WHERE c.class_id = ?
      AND NOT EXISTS (
        SELECT 1 
        FROM attendance_records ar 
        WHERE ar.student_id = s.student_id
          AND ar.class_id = ?
          AND ar.session_id = ?
          AND ar.session_date = ?
      )
      `,
      [class_id,session_id,date,class_id,class_id,session_id,date,]
    );

    // 👉 fake attendance_id (keep frontend same)
    const attendance_id = `${class_id}_${session_id}_${date}`;

    res.json({ message: "Marked new students as present", attendance_id });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (conn) conn.release();
  }
});
router.get("/history", async (req, res) => {
  const { class_id, date, start_time, end_time } = req.query;

  if (!class_id || !date || !start_time || !end_time) {
    return res.status(400).json({ error: "Missing parameters" });
  }

  try {
    // 🔹 1. หา session + subject info
    const [sessionRows] = await pool.execute(
      `
      SELECT 
        c.class_id,
        cs.session_id,
        cs.start_time,
        cs.end_time,
        sub.subject_name
      FROM class_sessions cs
      JOIN classes c ON c.class_id = cs.class_id
      JOIN subjects sub ON sub.subject_id = c.subject_id
      WHERE cs.class_id = ?
        AND cs.start_time = ?
        AND cs.end_time = ?
      LIMIT 1
      `,
      [class_id, start_time, end_time]
    );

    if (sessionRows.length === 0) {
      return res.status(404).json({ error: "Session not found" });
    }

    const session = sessionRows[0];

    // 🔹 2. ดึง attendance
    const [attendanceRecords] = await pool.execute(
      `
      SELECT
        s.student_id,
        s.full_name AS student_name,
        ar.status
      FROM attendance_records ar
      JOIN students s ON s.student_id = ar.student_id
      WHERE ar.class_id = ?
        AND ar.session_id = ?
        AND ar.session_date = ?
      ORDER BY s.student_id
      `,
      [class_id, session.session_id, date]
    );

    if (attendanceRecords.length === 0) {
      return res.status(404).json({ error: "No attendance records found" });
    }

    res.json({
      class_id: session.class_id,
      date: date,
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
        sub.subject_name,
        ar.session_date,
        TIME_FORMAT(cs.start_time, '%H:%i') AS start_time,
        TIME_FORMAT(cs.end_time, '%H:%i') AS end_time,
        ar.class_id,
        ar.session_id
      FROM attendance_records ar
      JOIN classes c ON ar.class_id = c.class_id
      JOIN subjects sub ON c.subject_id = sub.subject_id
      JOIN class_sessions cs ON ar.session_id = cs.session_id
      WHERE c.teacher_id = ?
      ORDER BY sub.subject_name, ar.session_date, cs.start_time
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

router.get("/admin/subjects", authMiddleware, async (req, res) => {
  const { year, group } = req.query;

  try {
    const [rows] = await pool.execute(`
      SELECT 
        c.class_id,
        s.subject_name
      FROM classes c
      JOIN subjects s ON c.subject_id = s.subject_id
      JOIN homeroom_classes h ON c.homeroom_id = h.homeroom_id
      WHERE h.class_year = ? AND h.group_number = ?
    `, [year, group]);

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server error");
  }
});

router.get("/admin/dates", authMiddleware, async (req, res) => {
  const { class_id } = req.query;

  try {
    const [rows] = await pool.execute(`
      SELECT DISTINCT session_date
      FROM attendance_records
      WHERE class_id = ?
      ORDER BY session_date DESC
    `, [class_id]);

    const result = rows.map(r => r.session_date);
    console.log('result dasdasd',result);
    res.json(result);
    
  } catch (err) {
    console.error(err);
    res.status(500).send("Server error");
  }
});

router.get("/admin/times", authMiddleware, async (req, res) => {
  const { class_id, date } = req.query;
  
  try {
    const formattedDate = date.split("T")[0];
    console.log('format',formattedDate);
    console.log('classid',class_id);
    
    const [rows] = await pool.execute(`
      SELECT DISTINCT
        cs.session_id,
        cs.start_time,
        cs.end_time,
        CONCAT(cs.start_time, ' - ', cs.end_time) AS label
      FROM attendance_records ar
      JOIN class_sessions cs 
        ON ar.session_id = cs.session_id
      WHERE ar.class_id = ? 
        AND ar.session_date = ?
      ORDER BY cs.start_time
    `, [class_id, formattedDate]);

    console.log('rows',rows);
    
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server error");
  }
});

router.get("/schedule", authMiddleware, async (req, res) => {
  const userId = req.user.user_id;

  const [rows] = await pool.execute(`
    SELECT 
      cs.day_of_week,
      cs.start_time,
      cs.end_time,
      s.subject_name,
      hc.class_year,
      hc.group_number,
      u.full_name AS teacher_name
    FROM class_sessions cs
    JOIN classes c ON cs.class_id = c.class_id
    JOIN subjects s ON c.subject_id = s.subject_id
    JOIN homeroom_classes hc ON c.homeroom_id = hc.homeroom_id
    LEFT JOIN users u ON c.teacher_id = u.user_id
    WHERE c.teacher_id = ?
    ORDER BY FIELD(cs.day_of_week,
      'Monday','Tuesday','Wednesday','Thursday','Friday'
    ), cs.start_time
  `, [userId]);

  res.json(rows);
});

router.get("/admin/schedule", async (req, res) => {
  const { year, group } = req.query;

    const [rows] = await pool.execute(`
      SELECT 
        cs.day_of_week,
        cs.start_time,
        cs.end_time,
        s.subject_name,
        u.full_name AS teacher_name
      FROM class_sessions cs
      JOIN classes c ON cs.class_id = c.class_id
      JOIN subjects s ON c.subject_id = s.subject_id
      JOIN homeroom_classes hc ON c.homeroom_id = hc.homeroom_id
      LEFT JOIN users u ON c.teacher_id = u.user_id
      WHERE hc.class_year = ? 
        AND hc.group_number = ?
      ORDER BY FIELD(cs.day_of_week,
        'Monday','Tuesday','Wednesday','Thursday','Friday'
      ), cs.start_time
    `, [year, group]);

  res.json(rows);
});

module.exports = router;
