import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart'; 
import 'screens/home_screen.dart'; 
import 'utils/languages.dart';


List<CameraDescription> cameras = [];

Future<void> main() async { 
  WidgetsFlutterBinding.ensureInitialized();

  
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