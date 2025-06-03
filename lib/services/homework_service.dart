import 'dart:convert';
import 'package:http/http.dart' as http;

final String baseUrl = 'http://192.168.196.87:3000';

class HomeworkService {
  static Future<List<Map<String, dynamic>>> fetchSubjects(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/homework/classes'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      throw Exception('Failed to load subjects');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchHomeworkList(
      String classId) async {
    final url = Uri.parse('$baseUrl/homework/$classId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List homeworkList = data['homeworkList'];



      return homeworkList.map<Map<String, dynamic>>((item) {
        // แปลงวันที่โดยใช้ DateTime และ timezone ที่ถูกต้อง
        DateTime dueDate = DateTime.parse(item['due_date']).toLocal();
        DateTime assignDate = DateTime.parse(item['assign_date']).toLocal();

        return {
          'homeworkId': item['homework_id'],
          'assignmentTitle': item['title'],
          'assignDate': assignDate.toIso8601String().split('T')[0],
          'dueDate': dueDate.toIso8601String().split('T')[0],
        };
      }).toList();

    } else {
      throw Exception('Failed to load homework');
    }
  }

  Future<bool> createHomework({
    required String classId,
    required String title,
    required String dueDate,
  }) async {
    final url = Uri.parse('$baseUrl/homework/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'class_id': classId,
        'title': title,
        'due_date': dueDate,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('Error creating homework: ${response.body}');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchStudentsByHomeworkId(String homeworkId) async {
    final response = await http.get(Uri.parse('$baseUrl/homework/$homeworkId/students'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['students']);
    } else {
      throw Exception('ไม่สามารถโหลดรายชื่อนักเรียนได้');
    }
  }

  static Future<void> submitHomework({
    required String homeworkId,
    required String submittedBy,
    required List<Map<String, dynamic>> records, // student_id + submitted (bool)
  }) async {
    final url = Uri.parse('$baseUrl/homework/submit');

    final body = {
      'homework_id': homeworkId,
      'submitted_by': submittedBy,
      'records': records,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit homework: ${response.body}');
    }
  }

  static Future<bool> deleteHomework(String homeworkId) async {
    final url = Uri.parse('$baseUrl/homework/$homeworkId');

    try {
      final response = await http.delete(url);

      print(homeworkId);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete homework. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting homework: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> checkMissingHomework() async {
    try {
      final url = Uri.parse('$baseUrl/homework/check-missing');
      final response = await http.post(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'message': data['message'],
          'updatedCount': data['updatedCount'],
          'checkedHomework': data['checkedHomework'],
          'currentDate': data['currentDate']
        };
      } else {
        throw Exception('Failed to check missing homework: ${response.body}');
      }
    } catch (e) {
      print('Error checking missing homework: $e');
      throw e;
    }
  }

  static Future<void> startAutoHomeworkCheck() async {
    try {
      print('\n=== Starting Auto Homework Check ===');
      print('Current time: ${DateTime.now().toLocal()}');
      
      // First check immediately for past homework
      await checkMissingHomework();
      
      // Then start periodic checks
      while (true) {
        await Future.delayed(Duration(minutes: 1));
        print('\n=== Auto Check at: ${DateTime.now().toLocal()} ===');
        final result = await checkMissingHomework();
        print('Check result: $result');
      }
    } catch (e) {
      print('Error in auto homework check: $e');
      throw e;
    }
  }

  static Future<Map<String, dynamic>> getServerTime() async {
    try {
      final url = Uri.parse('$baseUrl/homework/server-time');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to get server time: ${response.body}');
      }
    } catch (e) {
      print('Error getting server time: $e');
      throw e;
    }
  }
}
