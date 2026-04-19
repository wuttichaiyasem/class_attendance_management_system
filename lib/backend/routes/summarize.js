const express = require("express");
const router = express.Router();
const pool = require("../db");
const authMiddleware = require("../middleware/auth");
const crypto = require("crypto");

router.get("/admin/classes", async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        homeroom_id,
        CONCAT('ปี ', class_year) AS year,
        group_number AS \`group\`
      FROM homeroom_classes
      ORDER BY class_year, group_number
    `);

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server error");
  }
});

router.get("/admin/summary", authMiddleware, async (req, res) => {
  const { homeroom_id } = req.query;

  if (!homeroom_id) {
    return res.status(400).json({ error: "Missing homeroom_id" });
  }

  try {
    const [rows] = await pool.execute(
      `
      SELECT 
        s.student_id,
        s.full_name,
        SUM(CASE WHEN ar.status = 'absent' THEN 1 ELSE 0 END) AS absent,
        SUM(CASE WHEN ar.status = 'late' THEN 1 ELSE 0 END) AS late,
        SUM(CASE WHEN ar.status = 'personal_leave' THEN 1 ELSE 0 END) AS personal,
        SUM(CASE WHEN ar.status = 'sick_leave' THEN 1 ELSE 0 END) AS sick

      FROM students s
      LEFT JOIN attendance_records ar 
        ON s.student_id = ar.student_id

      WHERE s.homeroom_id = ?

      GROUP BY s.student_id
      ORDER BY s.student_id
      `,
      [homeroom_id]
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server error");
  }
});

router.get("/admin/student-details", authMiddleware, async (req, res) => {
  const { student_id } = req.query;

  if (!student_id) {
    return res.status(400).json({ error: "Missing student_id" });
  }

  try {
    const [rows] = await pool.execute(
      `
      SELECT 
        ar.student_id,
        ar.status,
        ar.session_date,
        sub.subject_name,
        cs.start_time,
        cs.end_time
      FROM attendance_records ar

      JOIN classes c ON c.class_id = ar.class_id
      JOIN subjects sub ON sub.subject_id = c.subject_id
      LEFT JOIN class_sessions cs ON cs.session_id = ar.session_id

      WHERE ar.student_id = ?
      ORDER BY ar.session_date DESC
      `,
      [student_id]
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server error");
  }
});

module.exports = router;