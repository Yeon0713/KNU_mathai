import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // FastAPI 서버 주소 (내부망)
  final String _serverUrl = 'http://192.168.8.158:8000/api/report';

  Future<String> sendWarning(double? lat, double? lng, String? imagePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_serverUrl));

      // 파라미터 추가 (latitude, longitude)
      request.fields['latitude'] = (lat ?? 0.0).toString();
      request.fields['longitude'] = (lng ?? 0.0).toString();

      // 파일 추가 (file)
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('file', imagePath));
      } else {
        // [수정] 이미지가 없을 때(테스트 등) 422 에러 방지를 위해 더미 파일 전송
        // FastAPI가 'file' 필드를 필수로 요구하기 때문입니다.
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          [], // 빈 바이트
          filename: 'test_signal.txt',
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📡 서버 전송 결과: ${response.statusCode}");
      if (response.statusCode != 200) {
        print("❌ 서버 응답 내용: ${response.body}");
        return "실패 (${response.statusCode})";
      }
      return "성공 (200 OK)";
    } catch (e) {
      print("❌ 서버 전송 실패: $e");
      return "에러: $e";
    }
  }
}