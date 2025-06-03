import 'dart:convert';
import 'package:http/http.dart' as http;

final String baseUrl = 'http://192.168.196.87:3000';

class SubjectService {
  static Future<List<Map<String, dynamic>>> getMySubjects(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/subjects'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load subjects');
    }
  }
}

