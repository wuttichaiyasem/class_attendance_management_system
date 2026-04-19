const express = require("express");
const router = express.Router();
const pool = require("../db");
const authMiddleware = require("../middleware/auth");
const crypto = require("crypto");

router.get("/admin", authMiddleware, async (req, res) => {
    if (req.user.role !== 1) {
      return res.status(403).json({ message: "คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้" });
    }

    try {
      const [rows] = await pool.execute(
        `
        SELECT 
            u.user_id,
            u.full_name,
            u.email,
            h.class_year,
            h.group_number
        FROM users u
        LEFT JOIN homeroom_classes h
            ON u.user_id = h.homeroom_teacher_id
        WHERE u.role = 2
        ORDER BY
            h.class_year ASC,
            h.group_number ASC,
            u.user_id ASC;
        `
      );

      res.json(rows);
    } catch (err) {
      console.error("Get teacher users error:", err);
      res.status(500).json({ message: "เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้" });
    }
  }
);

router.put("/admin/:userId", authMiddleware, async (req, res) => {
    if (req.user.role !== 1) {
      return res.status(403).json({ message: "คุณไม่มีสิทธิ์ทำรายการนี้" });
    }

    const { userId } = req.params;

    try {
      const [result] = await pool.execute(
        `
        UPDATE users
        SET role = 2
        WHERE user_id = ?
        `,
        [userId]
      );

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: "ไม่พบผู้ใช้" });
      }

      res.json({ message: "เพิ่มผู้ใช้เป็นอาจารย์สำเร็จ" });
    } catch (err) {
      console.error("Add teacher error:", err);
      res.status(500).json({ message: "เกิดข้อผิดพลาดในการเพิ่ม role" });
    }
  }
);

router.put("/admin/remove/:userId", authMiddleware, async (req, res) => {
    if (req.user.role !== 1) {
      return res.status(403).json({ message: "คุณไม่มีสิทธิ์ทำรายการนี้" });
    }

    const { userId } = req.params;
    const conn = await pool.getConnection();

    try {
        await conn.beginTransaction();

        await conn.execute(
        `
        UPDATE homeroom_classes
        SET homeroom_teacher_id = NULL
        WHERE homeroom_teacher_id = ?
        `,
        [userId]
        );

        const [result] = await conn.execute(
        `
        UPDATE users
        SET role = 4
        WHERE user_id = ? AND role = 2
        `,
        [userId]
        );

        if (result.affectedRows === 0) {
        await conn.rollback();
        return res.status(404).json({
            message: "ไม่พบผู้ใช้ หรือผู้ใช้ไม่ใช่ role 2",
        });
        }

        await conn.commit();
      res.json({ message: "ลบผู้ใช้สำเร็จ" });
    } catch (err) {
      console.error("Remove teacher error:", err);
      res.status(500).json({ message: "เกิดข้อผิดพลาดในการเปลี่ยน role" });
    }
  }
);

router.post("/admin/assignhomeroom", async (req, res) => {
  const { year, group, teacher_id } = req.body;
    console.log('year : ',year);
    console.log('group : ',group);
    console.log('teacher : ',teacher_id);
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
      VALUES (?, ?, ?, ?)`,
      [homeroomId, year, group, teacher_id]
    );
  } else {
    homeroomId = rows[0].homeroom_id;

    await pool.execute(
      `UPDATE homeroom_classes
       SET homeroom_teacher_id=?
       WHERE homeroom_id=?`,
      [teacher_id, homeroomId]
    );
  }

  res.json({ success: true, homeroom_id: homeroomId });
});

router.put("/admin/assignhomeroom/remove",authMiddleware,async (req, res) => {
    if (req.user.role !== 1) {
      return res
        .status(403)
        .json({ message: "คุณไม่มีสิทธิ์ทำรายการนี้" });
    }

    const { userId, year, group } = req.body;

    if (!userId || !year || !group) {
      return res.status(400).json({ message: "ข้อมูลไม่ครบ" });
    }

    try {
      const [result] = await pool.execute(
        `
        UPDATE homeroom_classes
        SET homeroom_teacher_id = NULL
        WHERE class_year = ?
          AND group_number = ?
          AND homeroom_teacher_id = ?
        `,
        [year, group, userId]
      );

      if (result.affectedRows === 0) {
        return res.status(404).json({
          message: "ไม่พบข้อมูล homeroom หรือครูไม่ได้เป็นที่ปรึกษาห้องนี้",
        });
      }

      res.json({ message: "ลบครูประจำชั้นสำเร็จ" });
    } catch (err) {
      console.error("Remove homeroom error:", err);
      res.status(500).json({ message: "เกิดข้อผิดพลาด" });
    }
  }
);

module.exports = router;
