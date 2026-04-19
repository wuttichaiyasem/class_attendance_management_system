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
      SELECT 
        s.student_id, 
        s.full_name, 
        h.class_year, 
        h.group_number, 
        t.is_paid, 
        t.last_updated
      FROM students s
      JOIN tuition_status t 
          ON s.student_id = t.student_id
      JOIN homeroom_classes h 
          ON s.homeroom_id = h.homeroom_id
      WHERE h.homeroom_teacher_id = ?
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

router.get("/admin/status", authMiddleware, async (req, res) => {
  const userId = req.user.user_id;
  const userRole = req.user.role;
  const status = req.query.status || "all";
  const searchRaw = req.query.search; 
  const search = typeof searchRaw === "string" ? searchRaw.trim() : "";

  if (!userId) {
    return res.status(400).json({ message: "ไม่พบ user_id จาก token" });
  }

  if (userRole !== 1) {
    return res.status(403).json({ message: "คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้" });
  }

  try {
    let sql = `
      SELECT s.student_id, s.full_name,
             t.is_paid, t.last_updated
      FROM students s
      JOIN tuition_status t ON s.student_id = t.student_id
      WHERE 1 = 1
    `;
    const params = [];

    if (status === "paid") {
      sql += " AND t.is_paid = TRUE";
    } else if (status === "unpaid") {
      sql += " AND t.is_paid = FALSE";
    }

    if (search.length > 0) {
      if (/^\d+$/.test(search)) {
        sql += " AND CAST(s.student_id AS CHAR) LIKE ?";
        params.push(`%${search}%`);
      } else {
        sql += " AND s.full_name LIKE ?";
        params.push(`%${search}%`);
      }
    }

    const [rows] = await pool.execute(sql, params);
    res.status(200).json(rows);
  } catch (err) {
    console.error("Error fetching tuition status:", err);
    res.status(500).json({ message: "เกิดข้อผิดพลาดในการดึงข้อมูลค่าเทอม" });
  }
});

router.put("/admin/status/:studentId", authMiddleware,async (req, res) => {
  const userRole = req.user.role;
  const { studentId } = req.params;
  const { is_paid } = req.body;

  if (userRole !== 1) {
    return res.status(403).json({ message: "คุณไม่มีสิทธิ์ทำรายการนี้" });
  }

  if (typeof is_paid !== "boolean" && is_paid !== 0 && is_paid !== 1) {
    return res.status(400).json({ message: "ค่า is_paid ไม่ถูกต้อง" });
  }

  try {
    const [result] = await pool.execute(
      `
      UPDATE tuition_status
      SET is_paid = ?, last_updated = NOW()
      WHERE student_id = ?
      `,
      [is_paid ? 1 : 0, studentId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "ไม่พบนักศึกษา" });
    }

    res.json({ message: "อัปเดตสถานะสำเร็จ" });
  } catch (err) {
    console.error("Update status error:", err);
    res.status(500).json({ message: "เกิดข้อผิดพลาดในการอัปเดตสถานะ" });
  }
  }
);

module.exports = router;
