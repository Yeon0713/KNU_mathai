import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart'; 
import 'package:get_storage/get_storage.dart'; 
import 'screens/helmet_check_screen.dart'; // ★ 시작 화면 변경
import 'utils/languages.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('카메라 에러: $e');
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
      translations: Languages(),
      locale: const Locale('ko', 'KR'),
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        brightness: Brightness.dark,
      ),
      // ★ 앱 시작 시 헬멧 체크 화면으로 이동
      home: const HelmetCheckScreen(), 
    );
  }
}