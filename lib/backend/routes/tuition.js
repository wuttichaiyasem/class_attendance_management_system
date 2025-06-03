const express = require("express");
const router = express.Router();
const pool = require("../db");
const authMiddleware = require("../middleware/auth");

router.get("/status", authMiddleware, async (req, res) => {
  const userId = req.user.user_id; // ดึงจาก token
  const status = req.query.status || "all"; // ดึงจาก query

  if (!userId) {
    return res.status(400).json({ message: "ไม่พบ user_id จาก token" });
  }

  try {
    let sql = `
      SELECT s.student_id, s.full_name, s.class_year, s.group_number, 
             t.is_paid, t.last_updated
      FROM students s
      JOIN tuition_status t ON s.student_id = t.student_id
      WHERE s.homeroom_teacher_id = ?
    `;
    const params = [userId];

    if (status === "paid") {
      sql += " AND t.is_paid = TRUE";
    } else if (status === "unpaid") {
      sql += " AND t.is_paid = FALSE";
    }

    const [rows] = await pool.execute(sql, params);
    res.status(200).json(rows);
  } catch (err) {
    console.error("Error fetching tuition status:", err);
    res.status(500).json({ message: "เกิดข้อผิดพลาดในการดึงข้อมูลค่าเทอม" });
  }
});

module.exports = router;
