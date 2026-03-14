import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String baseUrl = 'https://private-finance-management.onrender.com/api';
  
  print('Attempting login to: $baseUrl/auth/login');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'admin@royalstarboys.com',
        'password': 'admin123',
      }),
    );
    
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('Headers: ${response.headers}');
  } catch (e) {
    print('Exception caught: $e');
  }
}
