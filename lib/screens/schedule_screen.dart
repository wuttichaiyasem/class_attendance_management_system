import 'package:auto_size_text/auto_size_text.dart';
import 'package:class_attendance_management_system/services/attendance_service.dart';
import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Map<String, dynamic>> schedule = [];

  Future<void> fetchSchedule() async {
    try {
      final result = await AttendanceService.fetchTeacherSchedule();

      setState(() {
        schedule = List<Map<String, dynamic>>.from(result);
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Map<String, List<Map<String, dynamic>>> groupByDay() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in schedule) {
      final day = item['day_of_week'] ?? 'Unknown';

      if (!grouped.containsKey(day)) {
        grouped[day] = [];
      }

      grouped[day]!.add(item);
    }

    return grouped;
  }

  String formatTime(String time) {
    return time.substring(0, 5);
  }

  String mapDayToThai(String day) {
    switch (day) {
      case 'Monday':
        return 'จันทร์';
      case 'Tuesday':
        return 'อังคาร';
      case 'Wednesday':
        return 'พุธ';
      case 'Thursday':
        return 'พฤหัสบดี';
      case 'Friday':
        return 'ศุกร์';
      case 'Saturday':
        return 'เสาร์';
      case 'Sunday':
        return 'อาทิตย์';
      default:
        return day;
    }
  }

  Color getDayColor(String day) {
    switch (day) {
      case 'Sunday':
        return Color(0xffE53935);
      case 'Monday':
        return Color(0xffFFD54F);
      case 'Tuesday':
        return Color(0xffF06292);
      case 'Wednesday':
        return Color(0xff66BB6A);
      case 'Thursday':
        return Color(0xffFFA726);
      case 'Friday':
        return Color(0xff42A5F5);
      case 'Saturday':
        return Color(0xff8E24AA);
      default:
        return Color(0xff00154C);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSchedule();
  }

  Widget build(BuildContext context) {
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
                  'ตารางสอน',
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
              padding: EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Builder(
                        builder: (context) {
                          final grouped = groupByDay();

                          if (schedule.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(child: Text("ไม่มีข้อมูล")),
                            );
                          }

                          return Column(
                            children: grouped.entries.map((entry) {
                              final day = entry.key;
                              final items = entry.value;

                              return Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🔹 Header (colored)
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: getDayColor(day),
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(15)),
                                      ),
                                      child: Text(
                                        "วัน${mapDayToThai(day)}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),

                                    // 🔹 Body (subjects)
                                    ...items.map((item) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // เวลา (keep as is)
                                                Text(
                                                  "เวลา: ${formatTime(item['start_time'])} - ${formatTime(item['end_time'])}",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xff00154C),
                                                    fontSize: 18,
                                                  ),
                                                ),

                                                SizedBox(height: 6),

                                                // รายวิชา
                                                RichText(
                                                  text: TextSpan(
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                    children: [
                                                      TextSpan(
                                                        text: "รายวิชา: ",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: item[
                                                                'subject_name'] ??
                                                            '',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                        children: [
                                                          const TextSpan(
                                                            text: "ปี: ",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                "${item['class_year'] ?? ''}",
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    RichText(
                                                      text: TextSpan(
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                        children: [
                                                          const TextSpan(
                                                            text: "ห้อง: ",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                "${item['group_number'] ?? ''}",
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 2),
                                                RichText(
                                                  text: TextSpan(
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                    children: [
                                                      TextSpan(
                                                        text: "อาจารย์ผู้สอน: ",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: item[
                                                                'teacher_name'] ??
                                                            'ไม่พบผู้สอน',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
