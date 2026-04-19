import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:class_attendance_management_system/screens/admin_add_student_screen.dart';

final String baseUrl = 'http://localhost:3000/student';

class StudentAdminService {
  static Future<List<Student>> getStudents(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Student.fromJson(e)).toList();
    } else {
      throw Exception('โหลดนักศึกษาไม่สำเร็จ');
    }
  }

  static Future<void> addStudent({
    required String token,
    required String studentId,
    required String fullName,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'student_id': studentId,
        'full_name': fullName,
        'email': email,
      }),
    );

    if (response.statusCode == 200) return;

    if (response.statusCode == 409) {
      throw Exception('รหัสนักศึกษาซ้ำ');
    }

    throw Exception('เพิ่มนักศึกษาไม่สำเร็จ');
  }

  static Future<void> deleteStudent({
    required String token,
    required String studentId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/remove/$studentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('ลบนักศึกษาไม่สำเร็จ');
    }
  }

  static Future<void> assignStudent({
    required String token,
    required String studentId,
    required int year,
    required int group,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/assign/$studentId');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'year': year,
        'group': group,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('กำหนดห้องให้นักเรียนไม่สำเร็จ');
    }
  }
}
