const express = require("express");
const router = express.Router();
const pool = require("../db");
const authMiddleware = require("../middleware/auth");
const crypto = require("crypto");

router.get("/admin", authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT
        s.student_id,
        s.full_name,
        s.email,
        hc.class_year,
        hc.group_number
      FROM students s
      LEFT JOIN homeroom_classes hc
        ON s.homeroom_id = hc.homeroom_id
      ORDER BY student_id
    `);

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "โหลดข้อมูลนักศึกษาไม่สำเร็จ" });
  }
});

router.post("/admin/add", authMiddleware, async (req, res) => {
  const { student_id, full_name, email } = req.body;

  if (!student_id || !full_name || !email) {
    return res.status(400).json({ message: "ข้อมูลไม่ครบ" });
  }

  try {
    await pool.execute(
      `INSERT INTO students (student_id, full_name, email)
       VALUES (?, ?, ?)`,
      [student_id, full_name, email]
    );

    res.json({ message: "เพิ่มนักศึกษาสำเร็จ" });
  } catch (err) {
    if (err.code === "ER_DUP_ENTRY") {
      return res.status(409).json({ message: "รหัสนักศึกษาซ้ำ" });
    }

    console.error("Add student error:", err);
    res.status(500).json({ message: "เพิ่มนักศึกษาไม่สำเร็จ" });
  }
});

router.delete("/admin/remove/:studentId", authMiddleware, async (req, res) => {
  const { studentId } = req.params;

  try {
    await pool.execute(
      `DELETE FROM students WHERE student_id = ?`,
      [studentId]
    );

    res.json({ message: "ลบนักศึกษาสำเร็จ" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "ลบนักศึกษาไม่สำเร็จ" });
  }
});

router.put("/admin/assign/:studentId", async (req, res) => {
  const { studentId } = req.params;
  const { year, group } = req.body;
  console.log(year);
  console.log(group);

  const [rows] = await pool.execute(
    `SELECT homeroom_id FROM homeroom_classes
     WHERE class_year=? AND group_number=?`,
    [year, group]
  );

  let homeroomId;

  if (rows.length === 0) {
    homeroomId = crypto.randomUUID();

    await pool.execute(
      `INSERT INTO homeroom_classes
      (homeroom_id, class_year, group_number, homeroom_teacher_id)
      VALUES (?, ?, ?, NULL)`,
      [homeroomId, year, group]
    );
  } else {
    homeroomId = rows[0].homeroom_id;
  }

  await pool.execute(
    `UPDATE students SET homeroom_id=? WHERE student_id=?`,
    [homeroomId, studentId]
  );

  res.json({ success: true, homeroom_id: homeroomId });
});

module.exports = router;