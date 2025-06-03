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
      c.class_year,
      c.group_number,
      cs.day_of_week,
      cs.start_time,
      cs.end_time
    FROM classes c
    JOIN subjects s ON c.subject_id = s.subject_id
    LEFT JOIN class_sessions cs ON c.class_id = cs.class_id
    WHERE c.user_id = ?
    ORDER BY c.class_year ASC, c.group_number ASC
  `;

  try {
    const conn = await pool.getConnection();
    const [results] = await conn.execute(query, [userId]);
    conn.release();

    const grouped = {};
    results.forEach(row => {
      const year = `ปีที่ ${row.class_year}`;
      if (!grouped[year]) grouped[year] = [];

      const dateOfThisWeek = row.day_of_week
        ? getDateOfThisWeekByDay(row.day_of_week)
        : null;

       console.log("Calculated date:", dateOfThisWeek, "| day_of_week:", row.day_of_week);

      grouped[year].push({
        class_id: row.class_id,
        subject_name: row.subject_name,
        group: row.group_number,
        day_of_week: row.day_of_week || null,
        date_this_week: dateOfThisWeek,
        time: row.start_time && row.end_time
          ? `${row.start_time} - ${row.end_time}`
          : null,
      });
    });

    const response = Object.entries(grouped).map(([year, subjects]) => ({
      year,
      subjects,
    }));

    res.json(response);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;
