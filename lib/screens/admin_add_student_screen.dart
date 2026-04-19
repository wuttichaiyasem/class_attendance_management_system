import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:class_attendance_management_system/services/student_service.dart';

class Student {
  final String id;
  final String name;
  final String email;
  final int? classYear;
  final int? groupNumber;

  Student({
    required this.id,
    required this.name,
    required this.email,
    this.classYear,
    this.groupNumber,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['student_id'].toString(),
      name: json['full_name'],
      email: json['email'],
      classYear: json['class_year'],
      groupNumber: json['group_number'],
    );
  }
}

class AdminAddStudentScreen extends StatefulWidget {
  const AdminAddStudentScreen({super.key});

  @override
  State<AdminAddStudentScreen> createState() => _AdminAddStudentScreenState();
}

class _AdminAddStudentScreenState extends State<AdminAddStudentScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Student> allStudents = [];
  List<Student> filteredStudents = [];
  int? filterYear;
  int? filterGroup;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return;

      final students = await StudentAdminService.getStudents(token);

      setState(() {
        allStudents = students;
        filteredStudents = List.from(students);
      });
    } catch (e) {
      debugPrint('Load students error: $e');
    }
  }

  void searchStudent(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredStudents = List.from(allStudents);
      });
      return;
    }

    setState(() {
      filteredStudents = allStudents.where((t) {
        final q = query.toLowerCase();
        return t.id.contains(q) ||
            t.name.toLowerCase().contains(q) ||
            t.email.toLowerCase().contains(q);
      }).toList();
    });
  }

  void applyFilters() {
    setState(() {
      filteredStudents = allStudents.where((s) {
        final yearOk = filterYear == null || s.classYear == filterYear;
        final groupOk = filterGroup == null || s.groupNumber == filterGroup;
        return yearOk && groupOk;
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
                  'จัดการข้อมูลนักศึกษา',
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
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          //   child: TextField(
          //     controller: searchController,
          //     onChanged: searchStudent,
          //     decoration: InputDecoration(
          //       hintText: 'ค้นหานักศึกษา',
          //       prefixIcon: const Icon(Icons.search),
          //       filled: true,
          //       fillColor: Colors.white,
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(12),
          //         borderSide: BorderSide.none,
          //       ),
          //     ),
          //   ),
          // ),
          // Row(
          //   children: [
          //     Expanded(
          //         child: DropdownButtonFormField<int?>(
          //       value: filterYear, // int?
          //       hint: const Text('ปี'),
          //       items: [
          //         const DropdownMenuItem<int?>(
          //           value: null,
          //           child: Text('ทั้งหมด'),
          //         ),
          //         ...List.generate(
          //           6,
          //           (i) => DropdownMenuItem<int?>(
          //             value: i + 1,
          //             child: Text('ปี ${i + 1}'),
          //           ),
          //         ),
          //       ],
          //       onChanged: (v) {
          //         setState(() => filterYear = v);
          //         applyFilters();
          //       },
          //     )),
          //     const SizedBox(width: 8),
          //     Expanded(
          //         child: DropdownButtonFormField<int?>(
          //       value: filterGroup,
          //       hint: const Text('ห้อง'),
          //       items: [
          //         const DropdownMenuItem<int?>(
          //           value: null,
          //           child: Text('ทั้งหมด'),
          //         ),
          //         ...List.generate(
          //           10,
          //           (i) => DropdownMenuItem<int?>(
          //             value: i + 1,
          //             child: Text('ห้อง ${i + 1}'),
          //           ),
          //         ),
          //       ],
          //       onChanged: (v) {
          //         setState(() => filterGroup = v);
          //         applyFilters();
          //       },
          //     )),
          //   ],
          // ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                /// 🔍 Search (logic เดิม)
                Row(
                  children: [
                    // const Text(
                    //   'ค้นหา : ',
                    //   style:
                    //       TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    // ),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xffEAEAEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        child: TextField(
                          controller: searchController,
                          onChanged: searchStudent,
                          decoration: const InputDecoration(
                            hintText: 'ค้นหานักศึกษา',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                /// 🔽 Year + Group (logic เดิมทั้งหมด)
                Row(
                  children: [
                    const Text(
                      'ปี : ',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xffEAEAEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            isExpanded: true,
                            value: filterYear,
                            hint: const Text('ทั้งหมด'),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('ทั้งหมด'),
                              ),
                              ...List.generate(
                                8,
                                (i) => DropdownMenuItem<int?>(
                                  value: i + 1,
                                  child: Text('${i + 1}'),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => filterYear = v);
                              applyFilters();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ห้อง : ',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xffEAEAEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            isExpanded: true,
                            value: filterGroup,
                            hint: const Text('ทั้งหมด'),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('ทั้งหมด'),
                              ),
                              ...List.generate(
                                5,
                                (i) => DropdownMenuItem<int?>(
                                  value: i + 1,
                                  child: Text('${i + 1}'),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => filterGroup = v);
                              applyFilters();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📋 List
          Expanded(
            child: filteredStudents.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่พบข้อมูล',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return StudentCard(
                        id: student.id,
                        name: student.name,
                        email: student.email,
                        classYear: student.classYear,
                        groupNumber: student.groupNumber,
                        onEdit: () {
                          int selectedYear = 1;
                          int selectedGroup = 1;

                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("กำหนดห้องเรียน"),
                                content: Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: selectedYear,
                                        decoration: const InputDecoration(
                                            labelText: "ปี"),
                                        items: List.generate(
                                          8,
                                          (i) => DropdownMenuItem(
                                            value: i + 1,
                                            child: Text("ปี ${i + 1}"),
                                          ),
                                        ),
                                        onChanged: (v) => selectedYear = v!,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: selectedGroup,
                                        decoration: const InputDecoration(
                                            labelText: "ห้อง"),
                                        items: List.generate(
                                          5,
                                          (i) => DropdownMenuItem(
                                            value: i + 1,
                                            child: Text("ห้อง ${i + 1}"),
                                          ),
                                        ),
                                        onChanged: (v) => selectedGroup = v!,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("ยกเลิก"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);

                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final token =
                                          prefs.getString('jwt_token');
                                      if (token == null) return;

                                      await StudentAdminService.assignStudent(
                                        token: token,
                                        studentId: student.id,
                                        year: selectedYear,
                                        group: selectedGroup,
                                      );

                                      loadStudents();
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
                                  const Text('ต้องการลบนักศึกษาคนนี้หรือไม่'),
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

                            await StudentAdminService.deleteStudent(
                              token: token,
                              studentId: student.id,
                            );

                            loadStudents();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ลบนักศึกษาสำเร็จ')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('ลบนักศึกษาไม่สำเร็จ')),
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
        onPressed: () => showAddStudentDialog(context, loadStudents),
        backgroundColor: const Color(0xffF9CA10),
        child: const Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final String id;
  final String name;
  final String email;
  final int? classYear;
  final int? groupNumber;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentCard({
    super.key,
    required this.id,
    required this.name,
    required this.email,
    this.classYear,
    this.groupNumber,
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
          if (classYear != null && groupNumber != null) ...[
            const SizedBox(height: 8),
            Chip(
              shape: const StadiumBorder(),
              avatar: const Icon(
                Icons.school,
                size: 15,
                color: Colors.blueGrey,
              ),
              label: Text(
                'ม.$classYear/$groupNumber',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.blueGrey.shade50,
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

void showAddStudentDialog(BuildContext context, VoidCallback onSuccess) {
  final idController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('เพิ่มนักศึกษา'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: 'รหัสนักศึกษา'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'อีเมล'),
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
              if (idController.text.isEmpty ||
                  nameController.text.isEmpty ||
                  emailController.text.isEmpty) {
                return;
              }

              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('jwt_token');
                if (token == null) return;

                await StudentAdminService.addStudent(
                  token: token,
                  studentId: idController.text.trim(),
                  fullName: nameController.text.trim(),
                  email: emailController.text.trim(),
                );

                Navigator.pop(context);
                onSuccess();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เพิ่มนักศึกษาสำเร็จ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เพิ่มนักศึกษาไม่สำเร็จ')),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
