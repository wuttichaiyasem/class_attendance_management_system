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
    // 🔹 1. หานักเรียนที่ขาดเรียน
    const [rows] = await conn.query(`
      SELECT 
        s.student_id, 
        s.full_name AS student_name, 
        sub.subject_id, 
        sub.subject_name, 
        COUNT(*) AS absent_count
      FROM attendance_records ar
      JOIN students s 
        ON ar.student_id = s.student_id
      JOIN classes c 
        ON ar.class_id = c.class_id
      JOIN subjects sub 
        ON c.subject_id = sub.subject_id
      WHERE ar.status = 'absent'
      GROUP BY s.student_id, sub.subject_id
      HAVING absent_count >= 1
    `);

    for (const row of rows) {
      const reasonText = `ขาดเกิน 3 ครั้งในวิชา ${row.subject_name}`;

      // 🔹 2. เช็คว่าแจ้งเตือนแล้วหรือยัง
      const [existing] = await conn.query(
        `
        SELECT 1 
        FROM parent_notifications 
        WHERE student_id = ? 
          AND reason LIKE ?
        `,
        [row.student_id, `%${reasonText}%`]
      );

      if (existing.length === 0) {
        // 🔹 3. หา line_id ผู้ปกครอง
        const [parents] = await conn.query(
          `SELECT line_id FROM parents WHERE student_id = ?`,
          [row.student_id]
        );

        if (parents.length > 0) {
          const lineId = parents[0].line_id;

          // 🔹 4. ส่งแจ้งเตือน
          await client.pushMessage(lineId, {
            type: "text",
            text: `แจ้งเตือน: นักเรียน ${row.student_name} ขาดเรียนเกิน 3 ครั้งในวิชา ${row.subject_name}`,
          });

          // 🔹 5. บันทึก notification
          await conn.query(
            `
            INSERT INTO parent_notifications (student_id, notified_at, reason) 
            VALUES (?, NOW(), ?)
            `,
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
