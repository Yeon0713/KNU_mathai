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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 언어 설정
            Text('language'.tr, style: _headerStyle),
            const SizedBox(height: 10),
            Row(
              children: [
                _langButton(controller, "한국어", "ko", "KR"),
                const SizedBox(width: 10),
                _langButton(controller, "English", "en", "US"),
              ],
            ),
            
            const Divider(color: Colors.grey, height: 40),

            // 2. AI 민감도 (위험 감지 기준)
            Text('ai_sensitivity'.tr, style: _headerStyle),
            const SizedBox(height: 20),
            
            // [수정됨] 0.5 ~ 1.0 범위 슬라이더
            Obx(() {
              double val = controller.confThreshold.value;
              String statusText;

              // 수치에 따른 상태 메시지
              if (val >= 0.85) statusText = "(매우 엄격)";
              else if (val >= 0.7) statusText = "(보통)";
              else statusText = "(매우 민감)";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${'confidence_desc'.tr}: ${(val * 100).toInt()}%",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: val >= 0.85 ? Colors.greenAccent : Colors.amber, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: val,
                    min: 0.5,  // 최소값 0.5
                    max: 1.0,  // 최대값 1.0
                    divisions: 10, // 0.05 단위로 끊어서 움직임
                    label: "${(val * 100).toInt()}%",
                    activeColor: Colors.redAccent, // 위험도 조절 느낌의 빨간색
                    onChanged: (newVal) => controller.confThreshold.value = newVal,
                  ),
                  const Text(
                    " * 수치가 낮을수록 작은 위험도 잡아내지만, 오작동할 수 있습니다.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              );
            }),

            const SizedBox(height: 30),

            // 3. IOU 설정 (기존 유지)
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${'iou_desc'.tr}: ${(controller.iouThreshold.value * 100).toInt()}%",
                  style: const TextStyle(color: Colors.white70),
                ),
                Slider(
                  value: controller.iouThreshold.value,
                  min: 0.1,
                  max: 0.9,
                  divisions: 8,
                  activeColor: Colors.blueGrey,
                  onChanged: (val) => controller.iouThreshold.value = val,
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  TextStyle get _headerStyle => const TextStyle(
      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);

  Widget _langButton(SettingsController controller, String label, String lang, String country) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white10,
        foregroundColor: Colors.white,
      ),
      onPressed: () => controller.changeLanguage(lang, country),
      child: Text(label),
    );
  }
}