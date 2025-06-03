const express = require("express");
const jwt = require("jsonwebtoken");
const router = express.Router();
const pool = require("../db"); // นี่คือ mysql2/promise pool
const SECRET_KEY = process.env.JWT_SECRET;

router.post("/login", async (req, res) => {
  const { username, name, email } = req.body;

  if (!username || !name || !email) {
    return res
      .status(400)
      .json({ error: "Missing required fields: username, name, or email" });
  }

  try {
    const conn = await pool.getConnection();

    // เช็คว่าผู้ใช้มีอยู่หรือไม่
    const [results] = await conn.execute(
      "SELECT * FROM users WHERE user_id = ?",
      [username]
    );

    if (results.length === 0) {
      // ยังไม่มีผู้ใช้ → เพิ่มใหม่
      await conn.execute(
        "INSERT INTO users (user_id, full_name, email) VALUES (?, ?, ?)",
        [username, name, email]
      );

      generateAndSendToken({ user_id: username, full_name: name, email });
    } else {
      // มีอยู่แล้ว → ใช้ข้อมูลเดิม
      generateAndSendToken(results[0]);
    }

    conn.release();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }

  function generateAndSendToken(user) {
    const payload = {
      user_id: user.user_id,
      full_name: user.full_name,
      email: user.email,
    };

    const token = jwt.sign(payload, SECRET_KEY, { expiresIn: "24h" });

    res.json({
      status: "ok",
      token,
      user: payload,
    });
  }
});

module.exports = router;
