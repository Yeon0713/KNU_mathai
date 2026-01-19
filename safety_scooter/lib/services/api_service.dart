import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final GetStorage _box = GetStorage();

  // [수정] 저장된 IP/Port를 기반으로 URL 동적 생성
  String get _serverUrl {
    String ip = _box.read('server_ip') ?? '192.168.8.158';
    String port = _box.read('server_port') ?? '8000';
    return 'http://$ip:$port/api/report';
  }

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

  // [추가] 서버 연결 상태 확인 (Root 경로)
  Future<String> checkConnection() async {
    try {
      String ip = _box.read('server_ip') ?? '192.168.8.158';
      String port = _box.read('server_port') ?? '8000';
      final uri = Uri.parse('http://$ip:$port/');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      // 연결은 되었으나 200이 아닐 수도 있음 (예: 404)
      return "Online (${response.statusCode})";
    } catch (e) {
      // 연결 실패 (타임아웃, 거부됨 등)
      return "Offline";
    }
  }
}