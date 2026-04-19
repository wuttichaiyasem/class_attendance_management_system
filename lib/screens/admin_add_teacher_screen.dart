import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:class_attendance_management_system/services/teacher_service.dart';

class Teacher {
  final String id;
  final String name;
  final String email;
  final List<Homeroom> homerooms;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.homerooms,
  });
}

class Homeroom {
  final int classYear;
  final int groupNumber;

  Homeroom({
    required this.classYear,
    required this.groupNumber,
  });

  factory Homeroom.fromJson(Map<String, dynamic> json) {
    return Homeroom(
      classYear: json['class_year'],
      groupNumber: json['group_number'],
    );
  }
}

class AdminAddTeacherScreen extends StatefulWidget {
  const AdminAddTeacherScreen({super.key});

  @override
  State<AdminAddTeacherScreen> createState() => _AdminAddTeacherScreenState();
}

class _AdminAddTeacherScreenState extends State<AdminAddTeacherScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Teacher> allTeachers = [];
  List<Teacher> filteredTeachers = [];

  @override
  void initState() {
    super.initState();
    loadTeachers();
  }

  Future<void> loadTeachers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return;

      final teachers = await TeacherAdminService.getTeachers(token: token);

      setState(() {
        allTeachers = teachers;
        filteredTeachers = List.from(teachers);
      });
    } catch (e) {
      debugPrint('Load teachers error: $e');
    }
  }

  void searchTeacher(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredTeachers = List.from(allTeachers);
      });
      return;
    }

    setState(() {
      filteredTeachers = allTeachers.where((t) {
        final q = query.toLowerCase();
        return t.id.contains(q) ||
            t.name.toLowerCase().contains(q) ||
            t.email.toLowerCase().contains(q);
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
                  'จัดการข้อมูลอาจารย์',
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
              onChanged: searchTeacher,
              decoration: InputDecoration(
                hintText: 'ค้นหาอาจารย์',
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

          Expanded(
            child: filteredTeachers.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่พบข้อมูล',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTeachers.length,
                    itemBuilder: (context, index) {
                      final teacher = filteredTeachers[index];
                      return TeacherCard(
                        id: teacher.id,
                        name: teacher.name,
                        email: teacher.email,
                        homerooms: teacher.homerooms,
                        onEdit: () {
                          int selectedYear = 1;
                          int selectedGroup = 1;

                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("กำหนดครูประจำชั้น"),
                                content: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.65,
                                  ),
                                  child: SingleChildScrollView(
                                    child: StatefulBuilder(
                                      builder: (context, setState) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            /// YEAR + GROUP
                                            Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                      DropdownButtonFormField<
                                                          int>(
                                                    value: selectedYear,
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: "ปี",
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    items: List.generate(
                                                      8,
                                                      (i) => DropdownMenuItem(
                                                        value: i + 1,
                                                        child:
                                                            Text("ปี ${i + 1}"),
                                                      ),
                                                    ),
                                                    onChanged: (v) => setState(
                                                        () =>
                                                            selectedYear = v!),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child:
                                                      DropdownButtonFormField<
                                                          int>(
                                                    value: selectedGroup,
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: "ห้อง",
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    items: List.generate(
                                                      5,
                                                      (i) => DropdownMenuItem(
                                                        value: i + 1,
                                                        child: Text(
                                                            "ห้อง ${i + 1}"),
                                                      ),
                                                    ),
                                                    onChanged: (v) => setState(
                                                        () =>
                                                            selectedGroup = v!),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 20),

                                            if (teacher.homerooms.isNotEmpty)
                                              Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 8,
                                                runSpacing: 8,
                                                children:
                                                    teacher.homerooms.map((h) {
                                                  return Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .blueGrey.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                        color: Colors
                                                            .blueGrey.shade200,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.school,
                                                          size: 16,
                                                          color:
                                                              Colors.blueGrey,
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(
                                                          'ม.${h.classYear}/${h.groupNumber}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        GestureDetector(
                                                          onTap: () async {
                                                            try {
                                                              final prefs =
                                                                  await SharedPreferences
                                                                      .getInstance();
                                                              final token = prefs
                                                                  .getString(
                                                                      'jwt_token');
                                                              if (token == null)
                                                                return;

                                                              await TeacherAdminService
                                                                  .removeHomeroom(
                                                                token: token,
                                                                userId:
                                                                    teacher.id,
                                                                year:
                                                                    h.classYear,
                                                                group: h
                                                                    .groupNumber,
                                                              );

                                                              Navigator.pop(
                                                                  context);
                                                              loadTeachers();

                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                    content: Text(
                                                                        'ลบครูประจำชั้นสำเร็จ')),
                                                              );
                                                            } catch (e) {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                    content: Text(
                                                                        'ไม่สามารถลบได้')),
                                                              );
                                                            }
                                                          },
                                                          child: const Icon(
                                                            Icons.close,
                                                            size: 16,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("ยกเลิก"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);

                                      try {
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        final token =
                                            prefs.getString('jwt_token');
                                        if (token == null) return;

                                        await TeacherAdminService
                                            .assignHomeroom(
                                          token: token,
                                          userId: teacher.id,
                                          year: selectedYear,
                                          group: selectedGroup,
                                        );

                                        loadTeachers();

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'กำหนดครูประจำชั้นสำเร็จ')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('เกิดข้อผิดพลาด')),
                                        );
                                      }
                                    },
                                    child: const Text("ยืนยัน"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('ยืนยันการลบ'),
                              content:
                                  const Text('ต้องการลบอาจารย์คนนี้หรือไม่'),
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

                            await TeacherAdminService.removeTeacher(
                              token: token,
                              userId: teacher.id,
                            );

                            loadTeachers();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ลบอาจารย์สำเร็จ')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('เกิดข้อผิดพลาด')),
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
        onPressed: () => showAddIdDialog(context, loadTeachers),
        backgroundColor: const Color(0xffF9CA10),
        child: const Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}

class TeacherCard extends StatelessWidget {
  final String id;
  final String name;
  final String email;
  final List<Homeroom> homerooms;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TeacherCard({
    super.key,
    required this.id,
    required this.name,
    required this.email,
    required this.homerooms,
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
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.email, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          if (homerooms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 3,
              children: homerooms.map((h) {
                return Chip(
                  shape: const StadiumBorder(),
                  avatar: const Icon(
                    Icons.school,
                    size: 15,
                    color: Colors.blueGrey,
                  ),
                  label: Text(
                    'ม.${h.classYear}/${h.groupNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: Colors.blueGrey.shade50,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
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

void showAddIdDialog(BuildContext context, VoidCallback onSuccess) {
  final TextEditingController idController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('เพิ่มรหัสอาจารย์'),
        content: TextField(
          controller: idController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'รหัสผู้ใช้',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            child: const Text('เพิ่ม'),
            onPressed: () async {
              final userId = idController.text.trim();
              if (userId.isEmpty) return;

              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('jwt_token');
                if (token == null) return;

                await TeacherAdminService.addTeacher(
                  token: token,
                  userId: userId,
                );

                Navigator.pop(context);
                onSuccess();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เพิ่มอาจารย์สำเร็จ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ไม่สามารถเพิ่มอาจารย์ได้')),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
