import 'dart:convert';
import 'package:class_attendance_management_system/screens/admin_add_teacher_screen.dart';
import 'package:http/http.dart' as http;

final String baseUrl = 'http://localhost:3000/teacher';

class TeacherAdminService {
  static Future<List<Teacher>> getTeachers({
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/admin');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('ไม่สามารถโหลดผู้ใช้ role 2 ได้');
    }

    final List<dynamic> data = jsonDecode(response.body);

    final Map<String, Teacher> map = {};

    for (final row in data) {
      final id = row['user_id'].toString();

      map.putIfAbsent(
        id,
        () => Teacher(
          id: id,
          name: row['full_name'],
          email: row['email'],
          homerooms: [],
        ),
      );

      if (row['class_year'] != null && row['group_number'] != null) {
        map[id]!.homerooms.add(Homeroom.fromJson(row));
      }
    }

    return map.values.toList();
  }

  static Future<void> addTeacher({
    required String token,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/$userId');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('ไม่สามารถเพิ่มผู้ใช้เป็น role 2 ได้');
    }
  }

  static Future<void> removeTeacher({
    required String token,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/remove/$userId');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('ไม่สามารถลบผู้ใช้จาก role 2 ได้');
    }
  }

  static Future<void> assignHomeroom({
    required String token,
    required String userId,
    required int year,
    required int group,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/assignhomeroom'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'teacher_id': userId,
        'year': year,
        'group': group,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Assign failed');
    }
  }

  static Future<void> removeHomeroom({
    required String token,
    required String userId,
    required int year,
    required int group,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/assignhomeroom/remove');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'year': year,
        'group': group,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('ลบ homeroom ไม่สำเร็จ');
    }
  }
}
