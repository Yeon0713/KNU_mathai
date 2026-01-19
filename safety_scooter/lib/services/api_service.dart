import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // FastAPI 서버 주소 (내부망)
  final String _serverUrl = 'http://192.168.8.158:8000/api/report';

  Future<void> sendWarning(double? lat, double? lng, String? imagePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_serverUrl));

      // 파라미터 추가 (latitude, longitude)
      request.fields['latitude'] = (lat ?? 0.0).toString();
      request.fields['longitude'] = (lng ?? 0.0).toString();

      // 파일 추가 (file)
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('file', imagePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📡 서버 전송 결과: ${response.statusCode}");
    } catch (e) {
      print("❌ 서버 전송 실패: $e");
    }
  }
}