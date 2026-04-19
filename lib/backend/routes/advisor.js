const express = require("express");
const router = express.Router();
const pool = require("../db");
const authMiddleware = require("../middleware/auth");

router.get("/", authMiddleware, async (req, res) => {
  const userId = req.user.user_id;

  if (!userId) {
    return res.status(401).json({
      error: "Unauthorized: Missing user_id in token",
    });
  }

  try {
    const conn = await pool.getConnection();

    // 🔹 1. ดึงนักเรียนใน homeroom ของครู
    const [students] = await conn.query(
      `
      SELECT 
        s.student_id,
        s.full_name
      FROM students s
      JOIN homeroom_classes h 
        ON s.homeroom_id = h.homeroom_id
      WHERE h.homeroom_teacher_id = ?
      ORDER BY s.student_id ASC
      `,
      [userId]
    );

    if (students.length === 0) {
      conn.release();
      return res.json([]);
    }

    // 🔹 2. ดึง summary เฉพาะนักเรียนกลุ่มนี้
    const studentIds = students.map(s => s.student_id);

    const [attendanceSummary] = await conn.query(
      `
      SELECT 
        ar.student_id,
        SUM(CASE WHEN ar.status = 'absent' THEN 1 ELSE 0 END) AS absent_count,
        SUM(CASE WHEN ar.status = 'late' THEN 1 ELSE 0 END) AS late_count,
        SUM(CASE WHEN ar.status = 'personal_leave' THEN 1 ELSE 0 END) AS personal_leave_count,
        SUM(CASE WHEN ar.status = 'sick_leave' THEN 1 ELSE 0 END) AS sick_leave_count,
        SUM(CASE WHEN ar.status = 'present' THEN 1 ELSE 0 END) AS present_count
      FROM attendance_records ar
      WHERE ar.student_id IN (?)
      GROUP BY ar.student_id
      `,
      [studentIds]
    );

    conn.release();

    // 🔹 3. map result
    const response = students.map((st) => {
      const summary =
        attendanceSummary.find((a) => a.student_id === st.student_id) || {};

      return {
        student_id: st.student_id,
        full_name: st.full_name,
        summary: {
          มาเรียน: summary.present_count || 0,
          สาย: summary.late_count || 0,
          ขาด: summary.absent_count || 0,
          ลากิจ: summary.personal_leave_count || 0,
          ลาป่วย: summary.sick_leave_count || 0,
        },
      };
    });

    res.json(response);

  } catch (err) {
    console.error("Error fetching advisor student data:", err);
    res.status(500).json({ error: err.message });
  }
});

router.get("/check", authMiddleware, async (req, res) => {
  console.log("🧩 teacherId from token:", req.user.id);

  const teacherId = req.user.id;

  try {
    const [rows] = await pool.query(
      `
      SELECT COUNT(*) AS count
      FROM students s
      JOIN homeroom_classes h 
        ON s.homeroom_id = h.homeroom_id
      WHERE h.homeroom_teacher_id = ?
      `,
      [teacherId]
    );

    console.log("🔍 Query result:", rows);

    const isAdvisor = rows[0].count > 0;
    res.json({ isAdvisor });
  } catch (error) {
    console.error("❌ Error checking advisor status:", error);
    res.status(500).json({ message: "Server error" });
  }
});

router.get("/:studentId", authMiddleware, async (req, res) => {
  const { studentId } = req.params;
  const teacherId = req.user.user_id;

  if (!teacherId) {
    return res.status(401).json({ error: "Unauthorized: Missing user_id in token" });
  }

  try {
    const conn = await pool.getConnection();

    const [studentRows] = await conn.query(
      `SELECT student_id, full_name 
       FROM students 
       WHERE student_id = ? AND homeroom_teacher_id = ?`,
      [studentId, teacherId]
    );

    if (studentRows.length === 0) {
      conn.release();
      return res.status(403).json({
        error: "คุณไม่มีสิทธิ์ดูข้อมูลของนักศึกษาคนนี้",
      });
    }

    const student = studentRows[0];

    const [rows] = await conn.query(
      `
      SELECT 
        sub.subject_name,
        ar.status,
        COUNT(*) AS count
      FROM attendance_records ar
      JOIN attendance_sessions ats ON ar.attendance_id = ats.attendance_id
      JOIN classes c ON ats.class_id = c.class_id
      JOIN subjects sub ON c.subject_id = sub.subject_id
      WHERE ar.student_id = ?
      GROUP BY sub.subject_name, ar.status
      `,
      [studentId]
    );

    conn.release();

    const summary = {
      ขาด: [],
      ลากิจ: [],
      ลาป่วย: [],
      สาย: [],
    };

    rows.forEach((row) => {
      const item = {
        subject_name: row.subject_name,
        count: row.count,
      };
      switch (row.status) {
        case "absent":
          summary["ขาด"].push(item);
          break;
        case "personal_leave":
          summary["ลากิจ"].push(item);
          break;
        case "sick_leave":
          summary["ลาป่วย"].push(item);
          break;
        case "late":
          summary["สาย"].push(item);
          break;
      }
    });

    res.json({
      student_id: student.student_id,
      full_name: student.full_name,
      summary,
    });
  } catch (err) {
    console.error("Error fetching student summary:", err);
    res.status(500).json({ error: "เกิดข้อผิดพลาดในระบบ" });
  }
});


router.get("/:studentId/attendance-summary", authMiddleware, async (req, res) => {
  const { studentId } = req.params;

  try {
    const conn = await pool.getConnection();

    const [rows] = await conn.query(
      `
      SELECT 
        ar.status,
        s.subject_name,
        ar.session_date
      FROM attendance_records ar
      JOIN classes c 
        ON ar.class_id = c.class_id
      JOIN subjects s 
        ON c.subject_id = s.subject_id
      WHERE ar.student_id = ?
      ORDER BY ar.session_date DESC;
      `,
      [studentId]
    );

    conn.release();

    console.log("✅ Attendance result:", rows.length, "records found");
    console.log("Status from DB:", rows.map(r => r.status));

    if (!rows.length) {
      return res.json({ studentId, records: [] });
    }

    // Mapping สถานะอังกฤษ → ไทย
    const statusMap = {
      absent: "ขาด",
      personal_leave: "ลากิจ",
      sick_leave: "ลาป่วย",
      late: "สาย"
    };

    // รวมข้อมูลตาม type และ subject
    const grouped = {};
    for (const row of rows) {
      const statusLower = row.status.toLowerCase();

      // ข้าม present
      if (statusLower === "present") continue;

      const type = statusMap[statusLower] || row.status;

      if (!grouped[type]) {
        grouped[type] = { type, count: 0, subjects: {} };
      }

      grouped[type].count++;

      if (!grouped[type].subjects[row.subject_name]) {
        grouped[type].subjects[row.subject_name] = [];
      }

      grouped[type].subjects[row.subject_name].push(row.session_date);
    }

    const records = Object.values(grouped).map((item) => ({
      type: item.type,
      count: item.count,
      subjects: Object.keys(item.subjects).map((subjectName) => ({
        subject_name: subjectName,
        dates: item.subjects[subjectName]
      }))
    }));

    // เรียงลำดับ: ขาด → สาย → ลากิจ → ลาป่วย
    const order = ["ขาด", "สาย", "ลากิจ", "ลาป่วย"];
    const sortedRecords = records.sort(
      (a, b) => order.indexOf(a.type) - order.indexOf(b.type)
    );

    // ดึงชื่อเต็มนักเรียน
    const [studentRows] = await pool.query(
      `SELECT full_name FROM students WHERE student_id = ?`,
      [studentId]
    );
    const fullName = studentRows.length ? studentRows[0].full_name : "";

    res.json({
      studentId,
      full_name: fullName,
      records: sortedRecords
    });

  } catch (error) {
    console.error("❌ Error fetching attendance summary:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});



module.exports = router;
