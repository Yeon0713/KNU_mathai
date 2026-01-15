import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart'; 
import 'package:get_storage/get_storage.dart'; // ★ 1. 패키지 추가
import 'screens/home_screen.dart'; 
import 'utils/languages.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init(); // ★ 2. 이 줄을 꼭 추가하세요! (저장소 깨우기)

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
      home: const HomeScreen(),
    );
  }
}