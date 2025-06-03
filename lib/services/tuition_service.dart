import 'dart:convert';
import 'package:http/http.dart' as http;

final String baseUrl = 'http://192.168.196.87:3000';

class TuitionService {
  static Future<List<Map<String, String>>> fetchTuitionData({
    required String token,
    required String selectedStatus,
  }) async {
    final queryParam = selectedStatus == 'ทั้งหมด'
        ? ''
        : selectedStatus == 'จ่ายแล้ว'
            ? '?status=paid'
            : '?status=unpaid';

    final response = await http.get(
      Uri.parse('$baseUrl/tuition/status$queryParam'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    print('Token: $token');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, String>>((item) {
        return {
          'id': item['student_id'],
          'name': item['full_name'],
          'status': item['is_paid'] == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย',
        };
      }).toList();
    } else {
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('ไม่สามารถโหลดข้อมูลค่าเทอมได้');
    }
  }
}
