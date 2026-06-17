import 'dart:io';
import 'dart:convert';

void main() async {
  final apiKey = 'AIzaSyBQ847pLfiA4gW2jlmTUgS1su1Zlw7FylE';
  final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final data = jsonDecode(responseBody);
    if (data['models'] != null) {
      for (var model in data['models']) {
        final name = model['name'] as String;
        final supportedMethods = List<String>.from(model['supportedGenerationMethods'] ?? []);
        if (supportedMethods.contains('generateContent')) {
          print(name);
        }
      }
    } else {
      print('No models found: $data');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
