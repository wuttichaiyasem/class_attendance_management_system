import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://192.168.196.87:3000';

  Future<Map<String, dynamic>> saveUser(String username, String name, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'name': name,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save user');
    }
  }

}

class ePassportLogin {
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('https://api.rmutsv.ac.th/elogin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData =
          jsonDecode(utf8.decode(response.bodyBytes));
      return responseData;
    } else {
      throw Exception('Failed to login');
    }
  }
}
