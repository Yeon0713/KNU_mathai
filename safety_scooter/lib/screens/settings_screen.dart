import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('settings_title'.tr, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView( // ★ 1. 화면이 작을 때 스크롤 가능하게 변경 (세로 오버플로우 방지)
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 언어 설정
              Text('language'.tr, style: _headerStyle),
              const SizedBox(height: 15),
              Row(
                children: [
                  _langButton(controller, "한국어", "ko", "KR"),
                  const SizedBox(width: 12),
                  _langButton(controller, "English", "en", "US"),
                ],
              ),
              
              const Divider(color: Colors.white24, height: 60),

              // 2. 위험 감지 민감도 설정
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ★ 2. 여기가 핵심 수정! Expanded로 감싸서 글자가 길면 줄바꿈 되도록 함
                  Expanded(
                    child: Text(
                      'ai_sensitivity'.tr, 
                      style: _headerStyle,
                      overflow: TextOverflow.ellipsis, // 혹시라도 너무 길면 ... 처리
                      maxLines: 2, 
                    ),
                  ),
                  const SizedBox(width: 10), // 글자와 숫자 사이 간격
                  
                  // 숫자 표시
                  Obx(() => Text(
                    controller.confThreshold.value.toStringAsFixed(2), 
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  )),
                ],
              ),
              const SizedBox(height: 10),
              
              Text(
                'sensitivity_info'.tr, 
                style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 20),

              // 슬라이더 (0.5 ~ 1.0)
              Obx(() => SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.blueAccent,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.blueAccent.withOpacity(0.2),
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                ),
                child: Slider(
                  value: controller.confThreshold.value,
                  min: 0.5, 
                  max: 1.0, 
                  divisions: 10, 
                  label: controller.confThreshold.value.toStringAsFixed(2),
                  onChanged: (val) {
                    controller.confThreshold.value = val;
                  },
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => const TextStyle(
      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold);

  Widget _langButton(SettingsController controller, String label, String lang, String country) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white12,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => controller.changeLanguage(lang, country),
      child: Text(label),
    );
  }
}