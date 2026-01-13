import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart'; // 1. 카메라 패키지 import 필수
import 'screens/home_screen.dart'; 

// 2. 전역 변수로 카메라 목록을 선언 (다른 파일에서도 쓸 수 있게)
List<CameraDescription> cameras = [];

Future<void> main() async { // 3. 비동기 처리를 위해 async 추가
  WidgetsFlutterBinding.ensureInitialized();

  // 4. 기기에서 사용 가능한 카메라 목록 가져오기
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('카메라를 찾을 수 없습니다: $e');
  }

  runApp(const SafetyScooterApp());
}

class SafetyScooterApp extends StatelessWidget {
  const SafetyScooterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Safety Scooter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        brightness: Brightness.dark, // 다크모드
      ),
      home: const HomeScreen(),
    );
  }
}