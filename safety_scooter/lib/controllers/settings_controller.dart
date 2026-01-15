import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  // 1. AI 위험 감지 기준 (Confidence Threshold)
  // 범위: 0.5 (민감함) ~ 1.0 (엄격함)
  // 기본값: 0.7 (70% 이상 확신할 때만 감지)
  var confThreshold = 0.7.obs; 

  // 2. 겹침 허용도 (IOU Threshold)
  var iouThreshold = 0.4.obs;

  // 3. 언어 설정
  void changeLanguage(String langCode, String countryCode) {
    var locale = Locale(langCode, countryCode);
    Get.updateLocale(locale);
  }
}