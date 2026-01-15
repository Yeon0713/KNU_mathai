import 'package:flutter/material.dart'; // ★ 이 줄이 없어서 에러가 난 겁니다! (꼭 추가)
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final box = GetStorage();

  // 1. 민감도 변수 (기본값 0.5)
  var confThreshold = 0.5.obs; 

  // 2. 소리 설정 변수 (기본값 켜짐)
  var isSoundOn = true.obs;

  @override
  void onInit() {
    super.onInit();
    // 저장된 값이 있으면 불러오기
    if (box.hasData('confThreshold')) {
      confThreshold.value = box.read('confThreshold');
    }
    if (box.hasData('isSoundOn')) {
      isSoundOn.value = box.read('isSoundOn');
    }
  }

  // 슬라이더 움직일 때 저장하는 함수
  void setConfThreshold(double val) {
    confThreshold.value = val;
    box.write('confThreshold', val); 
  }

  // 소리 스위치 켤 때 저장하는 함수
  void toggleSound(bool val) {
    isSoundOn.value = val;
    box.write('isSoundOn', val);
  }

  void changeLanguage(String lang, String country) {
    // Locale을 쓰려면 맨 위에 material.dart가 있어야 함
    Get.updateLocale(Locale(lang, country));
  }
}