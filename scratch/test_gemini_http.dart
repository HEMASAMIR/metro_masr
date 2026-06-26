import 'dart:io';
import 'dart:convert';

void main() async {
  final apiKey = 'AIzaSyAqUr3eSodPnVq5glBKMw0RnbWGpTAOvuE';
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers.contentType = ContentType.json;
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'Hello'}
          ]
        }
      ]
    });
    request.write(body);
    final response = await request.close();
    print('Status Code: ${response.statusCode}');
    final responseBody = await response.transform(utf8.decoder).join();
    print('Response Body: $responseBody');
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
