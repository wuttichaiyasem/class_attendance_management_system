import 'package:class_attendance_management_system/services/attendance_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminHistoryScreen extends StatefulWidget {
  final String selectedSubject;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  AdminHistoryScreen({
    Key? key,
    this.selectedSubject = '',
    this.selectedDate,
    this.selectedTime,
  }) : super(key: key);

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  String? selectedSubject;
  String? selectedDate;
  int? selectedYear;
  int? selectedGroup;
  Map<String, dynamic>? selectedTimeOption;

  List<String> subjects = [];
  List<String> dates = [];
  List<Map<String, dynamic>> timeOptions = [];
  Map<String, String> subjectToClassId = {};
  String? selectedClassId;

  String? get selectedStartTime => selectedTimeOption?['start_time'];
  String? get selectedEndTime => selectedTimeOption?['end_time'];

  final Map<String, Color> statusColors = {
    'มาเรียน': Color(0xff57BC40),
    'สาย': Color(0xffEAA31E),
    'ขาด': Color(0xffE94C30),
    'ลากิจ': Color(0xff33A4C3),
    'ลาป่วย': Color(0xffAE62E2),
  };

  String mapStatusToThai(String status) {
    switch (status) {
      case 'present':
        return 'มาเรียน';
      case 'late':
        return 'สาย';
      case 'absent':
        return 'ขาด';
      case 'personal_leave':
        return 'ลากิจ';
      case 'sick_leave':
        return 'ลาป่วย';
      default:
        return status;
    }
  }

  String formatThaiDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final thaiDays = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์'
    ];
    final buddhistYear = date.year + 543;
    final dayName = thaiDays[date.weekday % 7];
    final dateFormatted = DateFormat('dd/MM').format(date);

    return '$dayName  $dateFormatted/$buddhistYear';
  }

  List<Map<String, dynamic>> attendanceData = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchAttendanceData() async {
    if (selectedClassId != null &&
        selectedDate != null &&
        selectedStartTime != null &&
        selectedEndTime != null) {
      final data = await AttendanceAdminService.fetchAttendanceHistory(
        classId: selectedClassId!,
        date: selectedDate!,
        startTime: selectedStartTime!,
        endTime: selectedEndTime!,
      );

      setState(() {
        attendanceData = data;
      });
    }
  }

  Future<void> fetchSubjects() async {
    if (selectedYear == null || selectedGroup == null) return;

    final result = await AttendanceAdminService.fetchSubjectsByYearAndGroup(
      year: selectedYear!,
      group: selectedGroup!,
    );

    setState(() {
      subjects = [];
      subjectToClassId.clear();

      for (var item in result) {
        final name = item['subject_name'];
        final classId = item['class_id'].toString();

        subjects.add(name);
        subjectToClassId[name] = classId;
      }

      selectedSubject = null;
      selectedDate = null;
      selectedTimeOption = null;
      dates = [];
      timeOptions = [];
      attendanceData = [];
    });
  }

  Future<void> fetchDates() async {
    if (selectedClassId == null) return;

    final result = await AttendanceAdminService.fetchDates(
      classId: selectedClassId!,
    );

    setState(() {
      dates = List<String>.from(result);

      selectedDate = null;
      selectedTimeOption = null;
      timeOptions = [];
      attendanceData = [];
    });
  }

  Future<void> fetchTimes() async {
    if (selectedClassId == null || selectedDate == null) return;

    final result = await AttendanceAdminService.fetchTimes(
      classId: selectedClassId!,
      date: selectedDate!,
    );

    setState(() {
      timeOptions = List<Map<String, dynamic>>.from(result);

      selectedTimeOption = null;
      attendanceData = [];
    });
  }

  Map<String, int> getSummary(List<Map<String, dynamic>> data) {
    int present = 0;
    int late = 0;
    int absent = 0;
    int personal_leave = 0;
    int sick_leave = 0;

    for (var record in data) {
      switch (record['status']) {
        case 'present':
          present++;
          break;
        case 'late':
          late++;
          break;
        case 'absent':
          absent++;
          break;
        case 'personal_leave':
          personal_leave++;
          break;
        case 'sick_leave':
          sick_leave++;
          break;
      }
    }

    return {
      'present': present,
      'late': late,
      'absent': absent,
      'personal_leave': personal_leave,
      'sick_leave': sick_leave,
    };
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> summary = getSummary(attendanceData);

    return Scaffold(
      backgroundColor: Color(0xffF3F3F3),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xff00154C),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.elliptical(200, 100)),
            ),
            padding: const EdgeInsets.only(top: 90, bottom: 60),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'ประวัติการเช็คชื่อ',
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                            Text('ปี : ',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600)),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: selectedYear,
                                decoration: InputDecoration(
                                  hint: Text('เลือกปี',
                                      style: TextStyle(fontSize: 17)),
                                  filled: true,
                                  fillColor: Color(0xffEAEAEA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: List.generate(
                                  8,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text("ปี ${i + 1}"),
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    selectedYear = v;
                                  });
                                  fetchSubjects();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('ห้อง : ',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600)),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: selectedGroup,
                                decoration: InputDecoration(
                                  hint: Text('เลือกห้อง',
                                      style: TextStyle(fontSize: 17)),
                                  filled: true,
                                  fillColor: Color(0xffEAEAEA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: List.generate(
                                  5,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text("ห้อง ${i + 1}"),
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    selectedGroup = v;
                                  });
                                  fetchSubjects();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('ชื่อวิชา : ',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xffEAEAEA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  value: subjects.contains(selectedSubject)
                                      ? selectedSubject
                                      : null,
                                  hint: Text(
                                    subjects.isEmpty
                                        ? 'ไม่มีข้อมูล'
                                        : 'เลือกวิชา',
                                    style: TextStyle(fontSize: 17),
                                  ),
                                  items: subjects.map((subject) {
                                    return DropdownMenuItem(
                                      value: subject,
                                      child: Text(subject,
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSubject = value;
                                      selectedClassId = subjectToClassId[value];
                                      selectedDate = null;
                                      selectedTimeOption = null;
                                      attendanceData = [];
                                    });
                                    fetchDates();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Text('วันที่ : ',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600)),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xffEAEAEA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      value: dates.contains(selectedDate)
                                          ? selectedDate
                                          : null,
                                      hint: Text(
                                        dates.isEmpty
                                            ? 'ไม่มีข้อมูล'
                                            : 'เลือกวันที่',
                                        style: TextStyle(fontSize: 17),
                                      ),
                                      items: dates.map((date) {
                                        return DropdownMenuItem(
                                          value: date,
                                          child: Text(
                                            formatThaiDate(date),
                                            style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedDate = value;
                                          selectedTimeOption = null;
                                          attendanceData = [];
                                        });

                                        fetchTimes();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Text('เวลา : ',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600)),
                                Expanded(
                                  child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xffEAEAEA),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      child:
                                          DropdownButton<Map<String, dynamic>>(
                                        isExpanded: true,
                                        value: selectedTimeOption,
                                        hint: Text(
                                          timeOptions.isEmpty
                                              ? 'ไม่มีข้อมูล'
                                              : 'เลือกเวลา',
                                        ),
                                        items: timeOptions.map((time) {
                                          return DropdownMenuItem<
                                              Map<String, dynamic>>(
                                            value: time,
                                            child: Text(time['label']),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedTimeOption = value;
                                          });

                                          fetchAttendanceData();
                                        },
                                      )),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (attendanceData.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สรุปการเช็คชื่อ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              buildSummaryItem(
                                  'มาเรียน', summary['present'] ?? 0),
                              buildSummaryItem('สาย', summary['late'] ?? 0),
                              buildSummaryItem('ขาด', summary['absent'] ?? 0),
                              buildSummaryItem(
                                  'ลากิจ', summary['personal_leave'] ?? 0),
                              buildSummaryItem(
                                  'ลาป่วย', summary['sick_leave'] ?? 0),
                            ],
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 20),
                  if (attendanceData.isNotEmpty)
                    Container(
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
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  _tableHeader('รหัสนักศึกษา', flex: 2),
                                  _tableHeader('ชื่อ–นามสกุล', flex: 3),
                                  _tableHeader('สถานะ', flex: 1),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 35),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: attendanceData.map((record) {
                                    final id = record['student_id']!;
                                    final name = record['name']!;
                                    final rawStatus = record['status'] ?? '';
                                    final status = mapStatusToThai(rawStatus);

                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 8),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                              color: Colors.grey.shade300),
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
                                                onPressed: () {},
                                                style: ElevatedButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  backgroundColor:
                                                      statusColors[status] ??
                                                          Colors.grey.shade300,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tableCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: AutoSizeText(
        text,
        style: TextStyle(fontSize: 16),
        maxLines: 1,
        minFontSize: 12,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget buildSummaryItem(String label, int count) {
    Color backgroundColor;

    switch (label) {
      case 'มาเรียน':
        backgroundColor = Color(0xff57BC40);
        break;
      case 'สาย':
        backgroundColor = Color(0xffEAA31E);
        break;
      case 'ขาด':
        backgroundColor = Color(0xffE94C30);
        break;
      case 'ลากิจ':
        backgroundColor = Color(0xff33A4C3);
        break;
      case 'ลาป่วย':
        backgroundColor = Color(0xffAE62E2);
        break;
      default:
        backgroundColor = Color(0xff00154C);
    }

    return Column(
      children: [
        Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: AutoSizeText(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
