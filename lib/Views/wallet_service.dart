import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletService {
  static Future<bool> deduct50NIS(String userName) async {
    const url = 'https://quickpark.onrender.com/api/wallet/deduct';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': userName,
          'amount': 50,
          'description': 'Overtime Fee',
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Backend error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending request: $e');
      return false;
    }
  }
}
