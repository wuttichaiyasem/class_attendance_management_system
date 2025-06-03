const express = require("express");
const router = express.Router();
const line = require("@line/bot-sdk");
const pool = require("../db");

const client = new line.Client({
  channelAccessToken: process.env.LINE_ACCESS_TOKEN,
  channelSecret: process.env.LINE_CHANNEL_SECRET,
});

router.post("/", (req, res) => {
  Promise.all(req.body.events.map(handleEvent))
    .then((result) => res.json(result))
    .catch((err) => {
      console.error("LINE Webhook Error:", err);
      res.status(500).end();
    });
});

async function handleEvent(event) {
  if (event.type !== "message" || event.message.type !== "text") {
    return Promise.resolve(null);
  }

  const text = event.message.text.trim();
  const lineId = event.source.userId;
  const conn = await pool.getConnection();

  try {
    // ===== คำสั่ง: ยกเลิกลิงก์ =====
    if (text.startsWith("ยกเลิกลิงก์")) {
      const parts = text.split(" ");
      if (parts.length !== 2) {
        await client.replyMessage(event.replyToken, {
          type: "text",
          text: `กรุณาระบุรหัสนักศึกษา เช่น "ยกเลิกลิงก์ 164404140090"`,
        });
        return;
      }

      const studentId = parts[1];

      const [result] = await conn.query(
        "DELETE FROM parents WHERE student_id = ? AND line_id = ?",
        [studentId, lineId]
      );

      if (result.affectedRows > 0) {
        await client.replyMessage(event.replyToken, {
          type: "text",
          text: `ยกเลิกลิงก์กับรหัสนักศึกษา ${studentId} เรียบร้อยแล้ว`,
        });
      } else {
        await client.replyMessage(event.replyToken, {
          type: "text",
          text: `ไม่พบการลิงก์กับรหัสนักศึกษา ${studentId}`,
        });
      }
      return;
    }

    // ===== คำสั่ง: ค่าเทอม =====
    if (text.toLowerCase() === "ค่าเทอม") {
      const [linkedStudents] = await conn.query(
        `SELECT s.student_id, s.full_name, t.is_paid, t.last_updated
        FROM parents p
        JOIN students s ON p.student_id = s.student_id
        LEFT JOIN tuition_status t ON s.student_id = t.student_id
        WHERE p.line_id = ?`,
        [lineId]
      );

      if (linkedStudents.length === 0) {
        await client.replyMessage(event.replyToken, {
          type: "text",
          text: `คุณยังไม่ได้เชื่อมโยงกับนักศึกษาคนใด`,
        });
        return;
      }

      let message = "📄 สถานะค่าเทอม:\n\n";
      for (const s of linkedStudents) {
        const status = s.is_paid
          ? `✅ จ่ายแล้ว (${s.last_updated || "ไม่ระบุ"})`
          : `❌ ยังไม่จ่าย`;
        message += `- ${s.full_name} (${s.student_id})\n  → ${status}\n\n`;
      }

      await client.replyMessage(event.replyToken, {
        type: "text",
        text: message,
      });
      return;
    }

    // ===== พยายามลิงก์ student_id ใหม่ =====
    const studentId = text;

    // ตรวจว่ารหัสนักศึกษามีอยู่ไหม
    const [students] = await conn.query(
      "SELECT full_name FROM students WHERE student_id = ?",
      [studentId]
    );

    if (students.length === 0) {
      await client.replyMessage(event.replyToken, {
        type: "text",
        text: `ไม่พบรหัสนักศึกษา: ${studentId} ในระบบ`,
      });
      return;
    }

    const studentName = students[0].full_name;

    // ตรวจว่ามีการลิงก์ student_id กับ lineId นี้อยู่แล้วหรือยัง
    const [existing] = await conn.query(
      "SELECT * FROM parents WHERE student_id = ? AND line_id = ?",
      [studentId, lineId]
    );

    if (existing.length > 0) {
      await client.replyMessage(event.replyToken, {
        type: "text",
        text: `บัญชี LINE นี้ได้เชื่อมโยงกับนักศึกษา ${studentName} (${studentId}) ไปแล้ว`,
      });
      return;
    }

    // ลิงก์ใหม่
    await conn.query(
      `
      INSERT INTO parents (student_id, line_id)
      VALUES (?, ?)
    `,
      [studentId, lineId]
    );

    await client.replyMessage(event.replyToken, {
      type: "text",
      text: `เชื่อมโยง LINE กับรหัสนักศึกษา ${studentId} (${studentName}) เรียบร้อยแล้ว`,
    });

  } catch (err) {
    console.error("handleEvent error:", err);
    await client.replyMessage(event.replyToken, {
      type: "text",
      text: `เกิดข้อผิดพลาดในการดำเนินการ กรุณาลองใหม่ภายหลัง`,
    });
  } finally {
    conn.release();
  }
}


module.exports = router;
