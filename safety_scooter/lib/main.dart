import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/home_screen.dart'; // 메인 화면 불러오기

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SafetyScooterApp());
}

class SafetyScooterApp extends StatelessWidget {
  const SafetyScooterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Safety Scooter', // 앱 이름
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent, // 전체적인 색감
        brightness: Brightness.dark, // 야간 주행 고려해서 다크모드 추천
      ),
      home: const HomeScreen(), // 여기가 바로 우리가 꾸밀 메인 화면
    );
  }
}