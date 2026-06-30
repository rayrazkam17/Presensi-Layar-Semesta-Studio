import 'dart:convert';

import 'package:http/http.dart' as http;

class WhatsAppService {
  static const functionUrl =
      'https://igzlwkmdoeavaarfnotr.supabase.co/functions/v1/send-attendance-whatsapp';

  Future<void> send(Map<String, dynamic> data) async {
    try {
      print("================================");
      print("WHATSAPP REQUEST");
      print("================================");
      print(jsonEncode(data));

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      print("================================");
      print("WHATSAPP RESPONSE");
      print("================================");
      print("STATUS : ${response.statusCode}");
      print("BODY   : ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
    } catch (e, s) {
      print("================================");
      print("WHATSAPP ERROR");
      print("================================");
      print(e);
      print(s);
      rethrow;
    }
  }
}