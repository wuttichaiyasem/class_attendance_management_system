const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const line = require("@line/bot-sdk");
require("dotenv").config();

const app = express();
app.use(cors());

const lineConfig = {
  channelAccessToken: process.env.LINE_ACCESS_TOKEN,
  channelSecret: process.env.LINE_CHANNEL_SECRET,
};

const cron = require("node-cron");
const notifyAbsences = require("./routes/notifyAbsences");

cron.schedule("* * * * *", () => {
  console.log("Running absence notification task every 1 minute...");
  notifyAbsences();
});

const lineRoutes = require("./routes/line");
app.use("/webhook", line.middleware(lineConfig), lineRoutes);

app.use(bodyParser.json());

const loginRoutes = require("./routes/login");
app.use("/auth", loginRoutes);

const subjectsRoutes = require("./routes/subjects");
app.use("/subjects", subjectsRoutes);

const attendanceRoutes = require("./routes/attendance");
app.use("/attendance", attendanceRoutes);

const homeworkRoutes = require("./routes/homework");
app.use("/homework", homeworkRoutes);

const tuitionRoutes = require("./routes/tuition");
app.use("/tuition", tuitionRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
