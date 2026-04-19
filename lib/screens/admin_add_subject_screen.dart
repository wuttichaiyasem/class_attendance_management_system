import 'package:class_attendance_management_system/services/subject_service.dart';
import 'package:class_attendance_management_system/services/teacher_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Subject {
  final String id;
  final String name;
  // final String teacher;

  Subject({
    required this.id,
    required this.name,
    // this.teacher,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['subject_id'].toString(),
      name: json['subject_name'],
    );
  }
}

class Teacher {
  final String id;
  final String name;

  Teacher({
    required this.id,
    required this.name,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['user_id'],
      name: json['full_name'],
    );
  }
}

class ScheduleSlot {
  String? sessionId;
  String day;
  String startTime;
  String endTime;
  String year;
  String group;

  ScheduleSlot({
    this.sessionId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.year,
    required this.group,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      sessionId: json['session_id'],
      day: convertDayToThai(json['day_of_week']),
      startTime: json['start_time'].substring(0, 5),
      endTime: json['end_time'].substring(0, 5),
      year: json['year'].toString(),
      group: json['group'].toString(),
    );
  }
}

String convertDayToEnglish(String thaiDay) {
  const map = {
    'จันทร์': 'Monday',
    'อังคาร': 'Tuesday',
    'พุธ': 'Wednesday',
    'พฤหัสบดี': 'Thursday',
    'ศุกร์': 'Friday',
    'เสาร์': 'Saturday',
    'อาทิตย์': 'Sunday',
  };

  return map[thaiDay] ?? thaiDay;
}

String convertDayToThai(String day) {
  switch (day.toLowerCase()) {
    case "monday":
      return "จันทร์";
    case "tuesday":
      return "อังคาร";
    case "wednesday":
      return "พุธ";
    case "thursday":
      return "พฤหัสบดี";
    case "friday":
      return "ศุกร์";
    case "saturday":
      return "เสาร์";
    case "sunday":
      return "อาทิตย์";
    default:
      return day;
  }
}

class AdminAddSubjectScreen extends StatefulWidget {
  const AdminAddSubjectScreen({super.key});

  @override
  State<AdminAddSubjectScreen> createState() => _AdminAddSubjectScreenState();
}

class _AdminAddSubjectScreenState extends State<AdminAddSubjectScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Subject> allSubjects = [];
  List<Subject> filteredSubjects = [];
  List<Teacher> teachers = [];

  final timeOptions = List.generate(
    24,
    (i) => '${i.toString().padLeft(2, '0')}:00',
  );

  @override
  void initState() {
    super.initState();
    loadSubjects();
    loadTeachers();
  }

  Future<void> loadSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return;

      final subjects = await SubjectAdminService.getSubjects(token);

      setState(() {
        allSubjects = subjects;
        filteredSubjects = List.from(subjects);
      });
    } catch (e) {
      debugPrint('Load subjects error: $e');
    }
  }

  Future<void> loadTeachers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return;

      final teachersList = await TeacherAdminService.getTeachers(token: token);

      setState(() {
        teachers =
            teachersList.map((t) => Teacher(id: t.id, name: t.name)).toList();
      });
    } catch (e) {
      debugPrint("Load teachers error: $e");
    }
  }

  void searchSubject(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredSubjects = List.from(allSubjects);
      });
      return;
    }

    setState(() {
      filteredSubjects = allSubjects.where((t) {
        final q = query.toLowerCase();
        return t.id.contains(q) || t.name.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // 🔵 Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xff00154C),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.elliptical(200, 100)),
            ),
            padding: const EdgeInsets.only(top: 90, bottom: 60),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'จัดการข้อมูลรายวิชา',
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),

          // 🔍 Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: searchSubject,
              decoration: InputDecoration(
                hintText: 'ค้นหารายวิชา',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📋 List
          Expanded(
            child: filteredSubjects.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่พบข้อมูล',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredSubjects.length,
                    itemBuilder: (context, index) {
                      final subject = filteredSubjects[index];
                      return SubjectCard(
                        id: subject.id,
                        subject_name: subject.name,
                        onEdit: () {
                          showEditSubjectDialog(
                            context,
                            subject: subject,
                            teachers: teachers,
                            onSuccess: loadSubjects,
                          );
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('ยืนยันการลบ'),
                              content: const Text('ต้องการลบรายวิชานี้หรือไม่'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('ยกเลิก'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('ลบ'),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('jwt_token');
                            if (token == null) return;

                            await SubjectAdminService.deleteSubject(
                              token: token,
                              subjectId: subject.id,
                            );

                            loadSubjects();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ลบรายวิชาสำเร็จ')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('ลบรายวิชาไม่สำเร็จ')),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),

      // ➕ FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddSubjectDialog(context, loadSubjects),
        backgroundColor: const Color(0xffF9CA10),
        child: const Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}

class SubjectCard extends StatelessWidget {
  final String id;
  final String subject_name;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SubjectCard({
    super.key,
    required this.id,
    required this.subject_name,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'รหัส: $id',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              _ActionButton(
                icon: Icons.edit,
                color: const Color.fromARGB(255, 243, 201, 33),
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.delete,
                color: Colors.red,
                onTap: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subject_name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showEditSubjectDialog(
  BuildContext context, {
  required Subject subject,
  required List<Teacher> teachers,
  required VoidCallback onSuccess,
}) async {
  List<ScheduleSlot> slots = [];
  String? selectedTeacherId;
  String? selectedYear;
  String? selectedGroup;
  String? homeroomId;

  int _toMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  bool isOverlapping(
    ScheduleSlot newSlot,
    List<ScheduleSlot> existingSlots,
  ) {
    int newStart = _toMinutes(newSlot.startTime);
    int newEnd = _toMinutes(newSlot.endTime);

    for (var slot in existingSlots) {
      if (slot.day != newSlot.day) continue;

      int oldStart = _toMinutes(slot.startTime);
      int oldEnd = _toMinutes(slot.endTime);

      if (newStart < oldEnd && newEnd > oldStart) {
        return true;
      }
    }
    return false;
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token != null) {
    final data = await SubjectAdminService.getSubjectSchedules(
      token: token,
      subjectId: subject.id,
    );

    selectedTeacherId = data['teacher_id'];

    slots = (data['schedules'] as List)
        .map((s) => ScheduleSlot.fromJson(s))
        .toList();
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade100,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('แก้ไขรายวิชา (${subject.name})'),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: teachers.any((t) => t.id == selectedTeacherId)
                          ? selectedTeacherId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'อาจารย์ผู้สอน',
                        border: OutlineInputBorder(),
                      ),
                      items: teachers
                          .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedTeacherId = v),
                    ),

                    const SizedBox(height: 20),

                    /// 📅 TEACHING TABLE
                    const Text(
                      'ตารางสอน',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (slots.isEmpty)
                      const Text(
                        'ยังไม่มีช่วงสอน',
                        style: TextStyle(color: Colors.grey),
                      ),

                    Column(
                      children: [
                        ...slots.asMap().entries.map((entry) {
                          final index = entry.key;
                          final slot = entry.value;

                          final days = [
                            'จันทร์',
                            'อังคาร',
                            'พุธ',
                            'พฤหัสบดี',
                            'ศุกร์',
                            'เสาร์',
                            'อาทิตย์'
                          ];

                          final timeOptions = List.generate(
                            24,
                            (i) => '${i.toString().padLeft(2, '0')}:00',
                          );

                          // List<ScheduleSlot> slots = [
                          //   ScheduleSlot(
                          //       day: 'จันทร์',
                          //       startTime: '09:00',
                          //       endTime: '11:00'),
                          // ];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: slot.day,
                                        isDense: true,
                                        decoration: const InputDecoration(
                                          labelText: 'วัน',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: days
                                            .map(
                                              (d) => DropdownMenuItem(
                                                value: d,
                                                child: Text(d),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => slot.day = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () async {
                                          final slot = slots[index];

                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          final token =
                                              prefs.getString('jwt_token');

                                          if (slot.sessionId != null &&
                                              token != null) {
                                            try {
                                              await SubjectAdminService
                                                  .deleteSubjectSchedule(
                                                token: token,
                                                sessionId: slot.sessionId!,
                                              );

                                              setState(
                                                  () => slots.removeAt(index));

                                              onSuccess();
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content:
                                                        Text('ลบไม่สำเร็จ')),
                                              );
                                            }
                                          } else {
                                            // local slot only
                                            setState(
                                                () => slots.removeAt(index));
                                          }
                                        }),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: slot.startTime,
                                        isDense: true,
                                        decoration: const InputDecoration(
                                          labelText: 'เริ่ม',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: timeOptions
                                            .map(
                                              (t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(t),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => slot.startTime = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('–'),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: slot.endTime,
                                        isDense: true,
                                        decoration: const InputDecoration(
                                          labelText: 'จบ',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: timeOptions
                                            .map(
                                              (t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(t),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) {
                                          final start =
                                              _toMinutes(slot.startTime);
                                          final end = _toMinutes(v!);

                                          if (end <= start) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'เวลาจบต้องมากกว่าเวลาเริ่ม'),
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() => slot.endTime = v);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                          value: slot.year,
                                          decoration: const InputDecoration(
                                            labelText: 'ปีการศึกษา',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: [
                                            '1',
                                            '2',
                                            '3',
                                            '4',
                                            '5',
                                            '6',
                                            '7',
                                            '8'
                                          ]
                                              .map((y) => DropdownMenuItem(
                                                    value: y,
                                                    child: Text('ปี $y'),
                                                  ))
                                              .toList(),
                                          onChanged: (v) {
                                            setState(() {
                                              slot.year = v!;
                                            });
                                          }),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                          value: slot.group,
                                          decoration: const InputDecoration(
                                            labelText: 'กลุ่ม',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: ['1', '2', '3', '4', '5']
                                              .map((g) => DropdownMenuItem(
                                                    value: g,
                                                    child: Text('กลุ่ม $g'),
                                                  ))
                                              .toList(),
                                          onChanged: (v) {
                                            setState(() {
                                              slot.group = v!;
                                            });
                                          }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                        /// ADD SLOT BUTTON
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('เพิ่มช่วงเวลา'),
                            onPressed: () {
                              setState(() {
                                slots.add(
                                  ScheduleSlot(
                                    day: 'จันทร์',
                                    startTime: '09:00',
                                    endTime: '10:00',
                                    year: '1',
                                    group: '1',
                                  ),
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedTeacherId == null || slots.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
                );
                return;
              }

              for (int i = 0; i < slots.length; i++) {
                final current = slots[i];
                final others = List<ScheduleSlot>.from(slots)..removeAt(i);

                if (isOverlapping(current, others)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('มีช่วงเวลาซ้ำกันในวันเดียวกัน'),
                    ),
                  );
                  return;
                }
              }

              final messenger = ScaffoldMessenger.of(context);

              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('jwt_token');
                if (token == null) {
                  print("❌ Token is null");
                  return;
                }

                final schedules = slots.map((s) {
                  return {
                    "year": int.parse(s.year),
                    "group": int.parse(s.group),
                    "day_of_week": convertDayToEnglish(s.day),
                    "start_time": s.startTime,
                    "end_time": s.endTime,
                  };
                }).toList();

                print("📤 Sending API request:");
                print("Teacher: $selectedTeacherId");
                print("Year: $selectedYear");
                print("Group: $selectedGroup");
                print("Schedules: $schedules");

                await SubjectAdminService.updateSubjectSchedule(
                  token: token,
                  subjectId: subject.id,
                  teacherId: selectedTeacherId!,
                  schedules: schedules,
                );
                print("✅ API success");
                onSuccess();
                Navigator.pop(context);

                messenger.showSnackBar(
                  const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
                );
              } catch (e, stack) {
                print("❌ API ERROR: $e");
                print(stack);

                messenger.showSnackBar(
                  const SnackBar(content: Text('บันทึกข้อมูลไม่สำเร็จ')),
                );
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      );
    },
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

void showAddSubjectDialog(BuildContext context, VoidCallback onSuccess) {
  final idController = TextEditingController();
  final nameController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('เพิ่มรายวิชา'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: 'รหัสรายวิชา'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'ชื่อรายวิชา'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            child: const Text('เพิ่ม'),
            onPressed: () async {
              if (idController.text.isEmpty || nameController.text.isEmpty)
                return;

              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('jwt_token');
                if (token == null) return;

                await SubjectAdminService.addSubject(
                  token: token,
                  subjectId: idController.text.trim(),
                  subjectName: nameController.text.trim(),
                );

                Navigator.pop(context);
                onSuccess();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เพิ่มรายวิชาสำเร็จ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เพิ่มรายวิชาไม่สำเร็จ')),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
