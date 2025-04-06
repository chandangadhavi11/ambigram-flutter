import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  ApiClient({required this.baseUrl});

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('\$baseUrl\$endpoint');
    return await http.get(url);
  }

  // Add more HTTP methods (post, put, delete) as needed.
}
