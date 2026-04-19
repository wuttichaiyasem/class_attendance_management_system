import 'package:class_attendance_management_system/services/attendance_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String classId;
  final String subjectName;
  final String date;
  final String dayOfWeek;
  final String time;

  const SubjectDetailScreen({
    Key? key,
    required this.classId,
    required this.subjectName,
    required this.date,
    required this.dayOfWeek,
    required this.time,
  }) : super(key: key);

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  Map<String, String> selectedStatuses = {};
  List<Map<String, String>> students = [];
  bool isAutoCheckingActive = false;

  String formatThaiDate(String isoDate, String dayOfWeek) {
    final date = DateTime.parse(isoDate);

    final thaiDaysMap = {
      'Monday': 'จันทร์',
      'Tuesday': 'อังคาร',
      'Wednesday': 'พุธ',
      'Thursday': 'พฤหัสบดี',
      'Friday': 'ศุกร์',
      'Saturday': 'เสาร์',
      'Sunday': 'อาทิตย์',
    };

    final buddhistYear = date.year + 543;
    final dateFormatted = DateFormat('dd/MM').format(date);

    final thaiDay = thaiDaysMap[dayOfWeek] ?? '';

    return '$thaiDay  $dateFormatted/$buddhistYear';
  }

  String formatShortTimeRange(String timeRange) {
    final parts = timeRange.split(' - ');
    if (parts.length != 2) return timeRange;

    final start = parts[0].substring(0, 5);
    final end = parts[1].substring(0, 5);

    return '$start - $end น.';
  }

  final List<String> statusOptions = [
    'มาเรียน',
    'สาย',
    'ขาด',
    'ลากิจ',
    'ลาป่วย'
  ];

  final Map<String, Color> statusColors = {
    'มาเรียน': Color(0xff57BC40),
    'สาย': Color(0xffEAA31E),
    'ขาด': Color(0xffE94C30),
    'ลากิจ': Color(0xff33A4C3),
    'ลาป่วย': Color(0xffAE62E2),
  };

  String mapStatusToDb(String status) {
    switch (status) {
      case 'มาเรียน':
        return 'present';
      case 'สาย':
        return 'late';
      case 'ขาด':
        return 'absent';
      case 'ลากิจ':
        return 'personal_leave';
      case 'ลาป่วย':
        return 'sick_leave';
      default:
        return 'absent';
    }
  }

  String? attendanceId;

  @override
  void initState() {
    super.initState();
    fetchStudents();
    _markAllPresent();
  }

  @override
  void dispose() {
    isAutoCheckingActive = false;
    super.dispose();
  }

  Future<void> _markAllPresent() async {
    final timeParts = widget.time.split(' - ');
    final startTime = timeParts[0];
    final endTime = timeParts[1];

    final prefs = await SharedPreferences.getInstance();
    final createdBy = prefs.getString('user_id') ?? '';

    if (createdBy.isEmpty) {
      print('ไม่พบ user_id');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่พบข้อมูลผู้ใช้'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      await AttendanceService.markAllPresent(
        classId: widget.classId,
        date: widget.date,
        startTime: startTime,
        endTime: endTime,
        createdBy: createdBy,
      );
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกไม่สำเร็จ'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> fetchStudents() async {
    final timeParts = widget.time.split(' - ');
    final startTime = timeParts[0];
    final endTime = timeParts[1];

    try {
      final fetchedStudents = await AttendanceService.fetchStudents(
        classId: widget.classId,
        date: widget.date,
        startTime: startTime,
        endTime: endTime,
      );

      setState(() {
        students.clear();
        students.addAll(fetchedStudents);

        selectedStatuses.clear();
        for (var student in fetchedStudents) {
          final studentId = student['id'] ?? '';
          final rawStatus = student['status'] ?? 'มาเรียน';
          String displayStatus;

          switch (rawStatus) {
            case 'present':
              displayStatus = 'มาเรียน';
              break;
            case 'late':
              displayStatus = 'สาย';
              break;
            case 'absent':
              displayStatus = 'ขาด';
              break;
            case 'personal_leave':
              displayStatus = 'ลากิจ';
              break;
            case 'sick_leave':
              displayStatus = 'ลาป่วย';
              break;
            default:
              displayStatus = 'มาเรียน';
          }

          selectedStatuses[studentId] = displayStatus;
        }
      });
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  Future<void> submitSingleAttendance(String studentId, String status) async {
    final timeParts = widget.time.split(' - ');
    final startTime = timeParts[0];
    final endTime = timeParts[1];

    final prefs = await SharedPreferences.getInstance();
    final createdBy = prefs.getString('user_id') ?? '';

    if (createdBy.isEmpty) {
      print('ไม่พบ user_id');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่พบข้อมูลผู้ใช้'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      await AttendanceService.submitAttendance(
        classId: widget.classId,
        date: widget.date,
        startTime: startTime,
        endTime: endTime,
        createdBy: createdBy,
        records: [
          {
            'student_id': studentId,
            'status': mapStatusToDb(status),
          }
        ],
      );

      print('บันทึกสำเร็จ: $studentId -> $status');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกสำเร็จ'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกไม่สำเร็จ'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF3F3F3),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xff00154C),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(200, 100),
              ),
            ),
            padding: const EdgeInsets.only(top: 90, bottom: 60),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'เช็คชื่อนักศึกษา',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Positioned(
                  left: 5,
                  top: -15,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ชื่อวิชา : ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xffEAEAEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: AutoSizeText(
                          widget.subjectName,
                          style: TextStyle(fontSize: 18),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'วันที่ : ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xffEAEAEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: AutoSizeText(
                          formatThaiDate(widget.date, widget.dayOfWeek),
                          style: TextStyle(fontSize: 18),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'เวลา : ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xffEAEAEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: AutoSizeText(
                          formatShortTimeRange(widget.time),
                          style: TextStyle(fontSize: 18),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Column(
                  children: [
                    Container(
                      color: Color(0xFF001B57),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          _tableHeader('รหัสนักศึกษา', flex: 2),
                          _tableHeader('ชื่อ–นามสกุล', flex: 3),
                          _tableHeader('สถานะ', flex: 1, textAlignCenter: true),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 35),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final id = student['id']!;
                          final name = student['name']!;
                          final status = selectedStatuses[id] ?? 'เลือก';

                          return Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                _tableCell(id, flex: 2),
                                _tableCell(name, flex: 3),
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 30,
                                    child: ElevatedButton(
                                      onPressed: () => _showStatusDialogFor(id),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        backgroundColor: status == 'เลือก'
                                            ? Colors.grey.shade300
                                            : statusColors[status],
                                        foregroundColor: status == 'เลือก'
                                            ? Colors.black
                                            : Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialogFor(String studentId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'เลือก',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: Colors.red),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...statusOptions.map((status) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColors[status],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedStatuses[studentId] = status;
                      });
                      Navigator.of(context).pop();
                      submitSingleAttendance(studentId, status);
                    },
                    child: Text(status, style: TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _tableHeader(String text, {int flex = 1, bool textAlignCenter = false}) {
  return Expanded(
    flex: flex,
    child: textAlignCenter
        ? Center(
            child: AutoSizeText(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              minFontSize: 12,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : AutoSizeText(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            minFontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
  );
}

Widget _tableCell(String text, {int flex = 1, bool textAlignCenter = false}) {
  return Expanded(
    flex: flex,
    child: textAlignCenter
        ? Center(
            child: AutoSizeText(
              text,
              style: TextStyle(fontSize: 16),
              maxLines: 1,
              minFontSize: 12,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : AutoSizeText(
            text,
            style: TextStyle(fontSize: 16),
            maxLines: 1,
            minFontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
  );
}
