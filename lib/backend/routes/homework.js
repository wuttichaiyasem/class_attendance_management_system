const express = require("express");
const router = express.Router();
const pool = require("../db");
const authMiddleware = require("../middleware/auth");


// GET /api/homework/classes
router.get("/classes", authMiddleware, async (req, res) => {
  const userId = req.user.user_id;

  try {
    const [rows] = await pool.query(`
    SELECT 
        c.class_id,
        c.class_year,
        c.group_number,
        s.subject_name
    FROM classes c
    JOIN subjects s ON c.subject_id = s.subject_id
    WHERE c.user_id = ?
    ORDER BY c.class_year, c.group_number
    `, [userId]);

    const grouped = {};

    rows.forEach(row => {
    const yearLabel = `ปีที่ ${row.class_year}`;
    if (!grouped[yearLabel]) grouped[yearLabel] = [];
    grouped[yearLabel].push({
        class_id: row.class_id,
        subject_name: `${row.subject_name} กลุ่มที่ ${row.group_number}`
    });
    });

    const response = Object.entries(grouped).map(([year, subjects]) => ({
    year,
    subjects
    }));

    res.json(response);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server error");
  }
});

const generateHomeworkId = () => {
  return `homework_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
};

router.post("/create" , async (req, res) => {
  const { class_id, title, due_date } = req.body;

  if (!class_id || !title || !due_date) {
    return res.status(400).json({ error: "Missing fields" });
  }

  const homework_id = generateHomeworkId();
  const assign_date = new Date().toISOString().split("T")[0];

  try {
    await pool.query(
      `INSERT INTO homework (homework_id, class_id, title, assign_date, due_date)
       VALUES (?, ?, ?, ?, ?)`,
      [homework_id, class_id, title, assign_date, due_date]
    );
    res.status(201).json({ message: "Homework created", homework_id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error" });
  }
});

router.get('/:class_id', async (req, res) => {
  const { class_id } = req.params;

  try {
    const [rows] = await pool.query(
      `SELECT homework_id, title, assign_date, due_date
       FROM homework
       WHERE class_id = ?
       ORDER BY due_date DESC`,
      [class_id]
    );

    res.json({ homeworkList: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch homework list' });
  }
});

router.get("/:homework_id/students", async (req, res) => {
  const { homework_id } = req.params;

  try {
    const conn = await pool.getConnection();

    // ดึง class_id ของการบ้านนี้
    const [homeworkRows] = await conn.execute(
      `SELECT class_id FROM homework WHERE homework_id = ?`,
      [homework_id]
    );

    if (homeworkRows.length === 0) {
      conn.release();
      return res.status(404).json({ error: "Homework not found" });
    }

    const class_id = homeworkRows[0].class_id;

    // ดึงนักเรียนในคลาส
    const [students] = await conn.execute(
      `
      SELECT s.student_id, s.full_name, hs.status, hs.submitted_at
      FROM class_students cs
      JOIN students s ON cs.student_id = s.student_id
      LEFT JOIN homework_submissions hs
        ON hs.student_id = s.student_id AND hs.homework_id = ?
      WHERE cs.class_id = ?
    `,
      [homework_id, class_id]
    );

    conn.release();

    res.json({ students });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.post("/submit", async (req, res) => {
  const { homework_id, submitted_by, records } = req.body;

  if (!homework_id || !submitted_by || !records)
    return res.status(400).json({ error: "Missing required fields" });

  let conn;

  try {
    conn = await pool.getConnection();

    // ตรวจสอบว่า homework นี้มีอยู่จริง
    const [hwRows] = await conn.execute(
      `SELECT * FROM homework WHERE homework_id = ?`,
      [homework_id]
    );

    if (hwRows.length === 0) {
      return res.status(404).json({ error: "Homework not found" });
    }

    for (const { student_id, status } of records) {
      await conn.execute(
        `
        INSERT INTO homework_submissions (homework_id, student_id, status, submitted_at)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE status = ?, submitted_at = NOW()
      `,
        [homework_id, student_id, status, status]
      );
    }

    res.json({ message: "Homework submission saved", homework_id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  } finally {
    if (conn) conn.release();
  }
});

// DELETE /homework/:homeworkId
router.delete('/:homeworkId', async (req, res) => {
  const { homeworkId } = req.params;

  try {
    // ลบจาก homework_submissions ก่อน
    await pool.execute(
      'DELETE FROM homework_submissions WHERE homework_id = ?',
      [homeworkId]
    );

    // แล้วจึงลบจาก homework
    const [result] = await pool.execute(
      'DELETE FROM homework WHERE homework_id = ?',
      [homeworkId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'ไม่พบการบ้านที่จะลบ' });
    }

    res.status(200).json({ message: 'ลบการบ้านสำเร็จ' });
  } catch (error) {
    console.error('Error deleting homework:', error);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการลบการบ้าน' });
  }
});

// Add a new endpoint to check and mark missing homework automatically
router.post("/check-missing", async (req, res) => {
  try {
    const conn = await pool.getConnection();

    // Get current date in YYYY-MM-DD format using local time
    const now = new Date();
    const currentDate = new Date(now.getTime() - (now.getTimezoneOffset() * 60000))
                         .toISOString().split('T')[0];

    // Get all homework where due date has passed
    const [overdueHomework] = await conn.execute(
      `
      SELECT 
        h.homework_id,
        h.class_id,
        h.title,
        h.due_date,
        DATE_FORMAT(h.due_date, '%Y-%m-%d') as formatted_due_date
      FROM homework h
      WHERE DATE(h.due_date) < DATE(?)
      ORDER BY h.due_date DESC
      `,
      [currentDate]
    );

    let updatedCount = 0;
    for (const homework of overdueHomework) {
      // Mark missing for students without any submission
      const [result] = await conn.execute(
        `
        INSERT INTO homework_submissions (homework_id, student_id, status, submitted_at)
        SELECT 
          ?, 
          cs.student_id, 
          'missing',
          NOW()
        FROM class_students cs
        WHERE cs.class_id = ?
        AND NOT EXISTS (
          SELECT 1 
          FROM homework_submissions hs 
          WHERE hs.homework_id = ?
          AND hs.student_id = cs.student_id
          AND hs.status IN ('submitted', 'late')
        )
        ON DUPLICATE KEY UPDATE 
          status = CASE 
            WHEN status IN ('submitted', 'late') THEN status
            ELSE 'missing'
          END,
          submitted_at = NOW()
      `,
        [homework.homework_id, homework.class_id, homework.homework_id]
      );
      
      updatedCount += result.affectedRows;
    }

    conn.release();
    res.json({ 
      message: "Checked and marked missing homework for past due dates",
      updatedCount,
      checkedHomework: overdueHomework.length,
      currentDate
    });
  } catch (err) {
    console.error("Error checking homework:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.get("/server-time", async (req, res) => {
  try {
    const currentDate = new Date();
    const formattedDate = currentDate.toISOString();
    console.log('Server time:', formattedDate);
    res.json({ 
      serverTime: formattedDate,
      timestamp: currentDate.getTime()
    });
  } catch (err) {
    console.error("Error getting server time:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
