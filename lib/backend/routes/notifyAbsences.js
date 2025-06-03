require("dotenv").config();
const line = require("@line/bot-sdk");
const pool = require("../db");

const client = new line.Client({
  channelAccessToken: process.env.LINE_ACCESS_TOKEN,
  channelSecret: process.env.LINE_CHANNEL_SECRET,
});

async function notifyAbsences() {
  const conn = await pool.getConnection();
  try {
    // 1. ดึงข้อมูลนักเรียนที่ขาดเกิน 3 ครั้งพร้อมวิชา
    const [rows] = await conn.query(`
      SELECT s.student_id, s.full_name AS student_name, sub.subject_id, sub.subject_name, COUNT(ar.status) AS absent_count
      FROM attendance_records ar
      JOIN attendance_sessions ats ON ar.attendance_id = ats.attendance_id
      JOIN students s ON ar.student_id = s.student_id
      JOIN classes c ON ats.class_id = c.class_id
      JOIN subjects sub ON c.subject_id = sub.subject_id
      WHERE ar.status = 'absent'
      GROUP BY s.student_id, sub.subject_id
      HAVING absent_count >= 1
    `);

    for (const row of rows) {
      const reasonText = `ขาด 1 ครั้งในวิชา ${row.subject_name}`;

      // 2. ตรวจสอบว่ามีการแจ้งเตือนซ้ำหรือยัง
      const [existing] = await conn.query(
        `SELECT * FROM parent_notifications WHERE student_id = ? AND reason LIKE ?`,
        [row.student_id, `%${reasonText}%`]
      );

      if (existing.length === 0) {
        // 3. ดึง line_id ของผู้ปกครอง
        const [parents] = await conn.query(
          `SELECT line_id FROM parents WHERE student_id = ?`,
          [row.student_id]
        );

        if (parents.length > 0) {
          // 4. ส่งข้อความแจ้งเตือน
          const lineId = parents[0].line_id;
          await client.pushMessage(lineId, {
            type: "text",
            text: `แจ้งเตือน: นักศึกษา ${row.student_name} ขาดเรียน 1 ครั้งในวิชา ${row.subject_name}`,
          });

          // 5. บันทึกการแจ้งเตือนลงฐานข้อมูล
          await conn.query(
            `INSERT INTO parent_notifications (student_id, notified_at, reason) VALUES (?, NOW(), ?)`,
            [row.student_id, reasonText]
          );
        }
      }
    }
  } catch (err) {
    console.error("notifyAbsences error:", err);
  } finally {
    conn.release();
  }
}

// ถ้ารันไฟล์นี้โดยตรง ให้เรียกฟังก์ชัน notifyAbsences
if (require.main === module) {
  notifyAbsences()
    .then(() => {
      console.log("Notification task finished.");
      process.exit(0);
    })
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}

module.exports = notifyAbsences;
