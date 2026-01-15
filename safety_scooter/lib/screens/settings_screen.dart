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
            // 언어 설정
            Text('language'.tr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                _langButton(controller, "한국어", "ko", "KR"),
                const SizedBox(width: 10),
                _langButton(controller, "English", "en", "US"),
              ],
            ),
            
            const Divider(color: Colors.grey, height: 40),

            // ★ AI 민감도 슬라이더 (여기가 핵심!)
            Text('ai_sensitivity'.tr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Obx(() {
              double val = controller.confThreshold.value;
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
                        // 값에 따라 상태 메시지 표시
                        val >= 0.7 ? 'sen_strict'.tr : (val >= 0.5 ? 'sen_balanced'.tr : 'sen_sensitive'.tr),
                        style: TextStyle(
                          color: val >= 0.7 ? Colors.greenAccent : Colors.amber, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: val,
                    min: 0.2, // 최소 20%
                    max: 0.9, // 최대 90%
                    divisions: 14, // 5% 단위로 조절
                    activeColor: Colors.amber,
                    // ★ 슬라이더 움직이면 값 저장!
                    onChanged: (newVal) => controller.setConfThreshold(newVal),
                  ),
                  Text(
                    'sen_help'.tr,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              );
            }),

            const Divider(color: Colors.grey, height: 40),

            // 소리 설정
            Text('sound_settings'.tr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.volume_up, color: Colors.white70),
                    const SizedBox(width: 10),
                    Text('sound_on'.tr, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                Obx(() => Switch(
                  value: controller.isSoundOn.value,
                  activeColor: Colors.amber,
                  onChanged: (val) => controller.toggleSound(val),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _langButton(SettingsController controller, String label, String lang, String country) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white),
      onPressed: () => controller.changeLanguage(lang, country),
      child: Text(label),
    );
  }
}