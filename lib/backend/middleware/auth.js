// middleware/auth.js
const jwt = require("jsonwebtoken");
const JWT_SECRET = process.env.JWT_SECRET;

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Authorization header missing or malformed" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    console.log("Decoded token:", decoded);

    // ✅ รวมข้อมูลเก่าเข้ากับใหม่ เพื่อไม่ทับ field เดิม
    req.user = {
      ...decoded, // เก็บทั้งหมดใน token เดิมไว้
      id: decoded.id || decoded.teacher_id || decoded.user_id || decoded.teacherId || null,
    };

    next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}

module.exports = authMiddleware; // ✅ Make sure this is a
