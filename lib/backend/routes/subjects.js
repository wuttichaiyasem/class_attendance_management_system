const express = require("express");
const router = express.Router();
const pool = require("../db");
const authMiddleware = require("../middleware/auth");
const crypto = require("crypto");

function getLocalDateString(date) {
  if (!(date instanceof Date)) {
    throw new Error("Invalid date object");
  }
  return date.toLocaleDateString("en-CA", { timeZone: "Asia/Bangkok" });
}

// ฟังก์ชันคำนวณวันในสัปดาห์นี้ตาม timezone ไทย
function getDateOfThisWeekByDay(dayStr) {
  const weekdayMap = {
    Monday: 1,
    Tuesday: 2,
    Wednesday: 3,
    Thursday: 4,
    Friday: 5,
    Saturday: 6,
    Sunday: 7,
  };

  const today = new Date();

  // หา offset ไปวันจันทร์ (week start)
  const todayDay = today.getDay();
  const mondayOffset = todayDay === 0 ? -6 : 1 - todayDay;
  const monday = new Date(today);
  monday.setDate(today.getDate() + mondayOffset);

  // หา target date จากวันจันทร์
  const targetOffset = weekdayMap[dayStr] - 1;
  const targetDate = new Date(monday);
  targetDate.setDate(monday.getDate() + targetOffset);

  // คืนค่าเป็นวันที่ตาม timezone ไทย
  return getLocalDateString(targetDate);
}

// GET /api/subjects/my
router.get("/", authMiddleware, async (req, res) => {
  const userId = req.user.user_id;

  if (!userId) {
    return res.status(401).json({ error: "Unauthorized: Missing user_id in token" });
  }

  const query = `
    SELECT 
      c.class_id,
      s.subject_name,
      h.class_year,
      h.group_number,
      cs.day_of_week,
      cs.start_time,
      cs.end_time
    FROM classes c
    JOIN subjects s 
      ON c.subject_id = s.subject_id
    JOIN homeroom_classes h 
      ON c.homeroom_id = h.homeroom_id
    LEFT JOIN class_sessions cs 
      ON c.class_id = cs.class_id
    WHERE c.teacher_id = ?
    ORDER BY h.class_year ASC, h.group_number ASC
  `;

  try {
    const conn = await pool.getConnection();
    const [results] = await conn.execute(query, [userId]);
    conn.release();

    const grouped = {};

    results.forEach(row => {
      const year = `ปีที่ ${row.class_year}`;
      if (!grouped[year]) grouped[year] = [];

      // prevent duplicate class entries
      const exists = grouped[year].some(c => c.class_id === row.class_id);

      if (!exists) {
        grouped[year].push({
          class_id: row.class_id,
          subject_name: row.subject_name,
          group: row.group_number,
          day_of_week: row.day_of_week || null,
          date_this_week: row.day_of_week
            ? getDateOfThisWeekByDay(row.day_of_week)
            : null,
          time:
            row.start_time && row.end_time
              ? `${row.start_time} - ${row.end_time}`
              : null,
        });
      }
    });

    const response = Object.entries(grouped).map(([year, subjects]) => ({
      year,
      subjects,
    }));
    console.log(response);
    res.json(response);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.get("/admin", authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT subject_id, subject_name
      FROM subjects
      ORDER BY subject_id
    `);

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "โหลดรายวิชาไม่สำเร็จ" });
  }
});

router.post("/admin/add", authMiddleware, async (req, res) => {
  const { subject_id, subject_name } = req.body;

  if (!subject_id || !subject_name) {
    return res.status(400).json({ message: "ข้อมูลไม่ครบ" });
  }

  try {
    await pool.execute(
      `INSERT INTO subjects (subject_id, subject_name)
       VALUES (?, ?)`,
      [subject_id, subject_name]
    );

    res.json({ message: "เพิ่มรายวิชาสำเร็จ" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "เพิ่มรายวิชาไม่สำเร็จ" });
  }
});

router.delete("/admin/remove/:subjectId", authMiddleware, async (req, res) => {
  const { subjectId } = req.params;

  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    await conn.execute(
      `DELETE cs FROM class_sessions cs
       JOIN classes c ON cs.class_id = c.class_id
       WHERE c.subject_id = ?`,
      [subjectId]
    );

    await conn.execute(
      `DELETE FROM classes WHERE subject_id = ?`,
      [subjectId]
    );

    await conn.execute(
      `DELETE FROM subjects WHERE subject_id = ?`,x
      [subjectId]
    );

    await conn.commit();

    res.json({ message: "ลบรายวิชาสำเร็จ" });

  } catch (err) {
    await conn.rollback();
    console.error(err);
    res.status(500).json({ message: "ลบรายวิชาไม่สำเร็จ" });
  } finally {
    conn.release();
  }
});

router.post("/admin/classes", async (req, res) => {
  const { subject_id, teacher_id, homeroom_id, schedules } = req.body;

  if (!subject_id || !homeroom_id) {
    return res.status(400).json({
      message: "subject_id and homeroom_id are required"
    });
  }

  const connection = await pool.getConnection();

  try {

    await connection.beginTransaction();

    // check if class already exists
    const [existing] = await connection.query(
      `SELECT class_id
       FROM classes
       WHERE subject_id = ?
       AND teacher_id <=> ?
       AND homeroom_id = ?`,
      [subject_id, teacher_id || null, homeroom_id]
    );

    let class_id;

    if (existing.length > 0) {

      // class already exists
      class_id = existing[0].class_id;

    } else {

      // create new class
      class_id = crypto.randomUUID();

      await connection.query(
        `INSERT INTO classes 
        (class_id, subject_id, teacher_id, homeroom_id)
        VALUES (?, ?, ?, ?)`,
        [
          class_id,
          subject_id,
          teacher_id || null,
          homeroom_id
        ]
      );

    }

    // insert schedules if provided
    if (schedules && schedules.length > 0) {

      for (const s of schedules) {

        const session_id = crypto.randomUUID();

      await connection.query(
        `INSERT INTO class_sessions
        (session_id, class_id, day_of_week, start_time, end_time, start_date, end_date)
        VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          session_id,
          class_id,
          s.day_of_week,
          s.start_time,
          s.end_time,
          s.start_date,
          s.end_date
        ]
      );

      }

    }

    await connection.commit();

    res.json({
      success: true,
      class_id: class_id
    });

  } catch (err) {
    await connection.rollback();
    if (err.code === "ER_DUP_ENTRY") {
      return res.status(400).json({
        success: false,
        message: "Schedule already exists for this class"
      });
    }

    console.error(err);

    res.status(500).json({
      success: false,
      message: "Failed to save class"
    });

  }finally {
    connection.release();
  }

});

router.get("/admin/:subjectId/schedule", async (req, res) => {
  const { subjectId } = req.params;

  try {
    const [rows] = await pool.execute(
      `SELECT 
        c.teacher_id,
        h.class_year,
        h.group_number,
        cs.session_id,
        cs.day_of_week,
        cs.start_time,
        cs.end_time
      FROM classes c
      JOIN homeroom_classes h ON c.homeroom_id = h.homeroom_id
      LEFT JOIN class_sessions cs ON cs.class_id = c.class_id
      WHERE c.subject_id = ?
      ORDER BY 
        h.class_year,
        h.group_number,
        FIELD(cs.day_of_week,
          'monday','tuesday','wednesday','thursday','friday','saturday','sunday'
        ),
        cs.start_time`,
      [subjectId]
    );

    if (rows.length === 0) {
      return res.json({
        teacher_id: null,
        schedules: []
      });
    }

    const teacherId = rows[0].teacher_id;

    const schedules = rows
      .filter(r => r.day_of_week)
      .map(r => ({
        session_id: r.session_id,
        year: r.class_year,
        group: r.group_number,
        day_of_week: r.day_of_week,
        start_time: r.start_time,
        end_time: r.end_time
      }));

    res.json({
      teacher_id: teacherId,
      schedules
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch schedule" });
  }
});

router.put("/admin/:subjectId/schedule", async (req, res) => {
  const { subjectId } = req.params;
  const { teacher_id, schedules } = req.body;

  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    for (const s of schedules) {
      const { year, group, day_of_week, start_time, end_time } = s;

      // 1️⃣ find homeroom
      const [rows] = await conn.execute(
        `SELECT homeroom_id FROM homeroom_classes
         WHERE class_year=? AND group_number=?`,
        [year, group]
      );

      let homeroomId;

      if (rows.length === 0) {
        homeroomId = crypto.randomUUID();

        await conn.execute(
          `INSERT INTO homeroom_classes
          (homeroom_id, class_year, group_number, homeroom_teacher_id)
          VALUES (?, ?, ?, NULL)`,
          [homeroomId, year, group]
        );
      } else {
        homeroomId = rows[0].homeroom_id;
      }

      // 2️⃣ find class
      const [classRows] = await conn.execute(
        `SELECT class_id FROM classes
         WHERE subject_id=? AND homeroom_id=?`,
        [subjectId, homeroomId]
      );

      let classId;

      if (classRows.length === 0) {
        classId = crypto.randomUUID();

        await conn.execute(
          `INSERT INTO classes
          (class_id, subject_id, teacher_id, homeroom_id)
          VALUES (?, ?, ?, ?)`,
          [classId, subjectId, teacher_id, homeroomId]
        );
      } else {
        classId = classRows[0].class_id;

        await conn.execute(
          `UPDATE classes
           SET teacher_id=?
           WHERE class_id=?`,
          [teacher_id, classId]
        );
      }

      // ❗ delete ONLY this class sessions (important)
      await conn.execute(
        `DELETE FROM class_sessions WHERE class_id=?`,
        [classId]
      );

      // 3️⃣ insert session
      await conn.execute(
        `INSERT INTO class_sessions
        (session_id, class_id, day_of_week, start_time, end_time)
        VALUES (?, ?, ?, ?, ?)`,
        [
          crypto.randomUUID(),
          classId,
          day_of_week,
          start_time,
          end_time
        ]
      );
    }

    await conn.commit();

    res.json({ success: true });

  } catch (err) {
    await conn.rollback();
    console.error(err);
    res.status(500).json({ error: "Failed to update schedule" });
  } finally {
    conn.release();
  }
});

router.delete("/admin/session/:sessionId", async (req, res) => {
  const { sessionId } = req.params;

  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    // 1️⃣ check if session exists
    const [rows] = await conn.execute(
      `SELECT session_id FROM class_sessions WHERE session_id=?`,
      [sessionId]
    );

    if (rows.length === 0) {
      await conn.rollback();
      return res.status(404).json({
        error: "Session not found"
      });
    }

    // 2️⃣ delete the session
    const [result] = await conn.execute(
      `DELETE FROM class_sessions WHERE session_id=?`,
      [sessionId]
    );

    await conn.commit();

    res.json({
      success: true,
      deleted_session_id: sessionId,
      affected_rows: result.affectedRows
    });

  } catch (err) {
    await conn.rollback();
    console.error(err);

    res.status(500).json({
      error: "Failed to delete session"
    });
  } finally {
    conn.release();
  }
});

module.exports = router;
