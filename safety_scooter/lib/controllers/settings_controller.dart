import 'dart:convert';
import 'package:flutter/material.dart'; // ★ 이 줄이 없어서 에러가 난 겁니다! (꼭 추가)
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsController extends GetxController with WidgetsBindingObserver {
  final box = GetStorage();

  // 1. 민감도 변수 (기본값 0.5)
  var confThreshold = 0.5.obs; 

  // 2. 소리 설정 변수 (기본값 켜짐)
  var isSoundOn = true.obs;

  // 3. 자동 리포트 (기본값 켜짐)
  var isAutoReportOn = true.obs;

  // 4. 모델 선택 (기본값 파일명)
  var selectedModel = "model.tflite".obs;
  var modelOptions = <String>["model.tflite"].obs; // 동적 목록 (RxList)

  // 5. 위치 권한 상태
  var locationPermissionStatus = PermissionStatus.denied.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // 앱 상태 감지 등록
    // 저장된 값이 있으면 불러오기
    if (box.hasData('confThreshold')) {
      confThreshold.value = box.read('confThreshold');
    }
    if (box.hasData('isSoundOn')) {
      isSoundOn.value = box.read('isSoundOn');
    }
    if (box.hasData('isAutoReportOn')) {
      isAutoReportOn.value = box.read('isAutoReportOn');
    }
    if (box.hasData('selectedModel')) {
      selectedModel.value = box.read('selectedModel');
    }

    // assets/models 폴더 스캔하여 목록 업데이트
    _loadModelList();
    
    // 초기 권한 확인
    checkLocationPermission();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // 감지 해제
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkLocationPermission(); // 앱으로 돌아올 때 권한 상태 갱신
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

  // 자동 리포트 스위치
  void toggleAutoReport(bool val) {
    isAutoReportOn.value = val;
    box.write('isAutoReportOn', val);
  }

  // 모델 변경
  void setModel(String val) {
    selectedModel.value = val;
    box.write('selectedModel', val);
  }

  void changeLanguage(String lang, String country) {
    // Locale을 쓰려면 맨 위에 material.dart가 있어야 함
    Get.updateLocale(Locale(lang, country));
  }

  // assets/models 폴더 내의 .tflite 파일 목록을 불러옴
  Future<void> _loadModelList() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // assets/models/ 경로에 있는 .tflite 파일만 필터링
      final models = manifestMap.keys
          .where((key) => key.startsWith('assets/models/') && key.endsWith('.tflite'))
          .map((key) => key.split('/').last) // 경로 제외하고 파일명만 추출
          .toList();

      if (models.isNotEmpty) {
        modelOptions.assignAll(models);

        // 현재 선택된 값이 목록에 없거나 레거시 값인 경우 처리
        String current = selectedModel.value;
        if (!models.contains(current)) {
          if (current == "Fast (Nano)" && models.contains("model.tflite")) {
            selectedModel.value = "model.tflite";
          } else if (current == "Accurate (Small)" && models.contains("model_s.tflite")) {
            selectedModel.value = "model_s.tflite";
          } else {
            selectedModel.value = models.first; // 목록의 첫 번째 파일로 대체
          }
          box.write('selectedModel', selectedModel.value);
        }
      }
    } catch (e) {
      print("❌ 모델 목록 로드 실패: $e");
    }
  }

  // 위치 권한 확인
  Future<void> checkLocationPermission() async {
    locationPermissionStatus.value = await Permission.location.status;
  }

  // 위치 권한 요청
  Future<void> requestLocationPermission() async {
    print("📍 [Debug] 위치 권한 요청 시작...");
    final status = await Permission.location.request();
    print("📍 [Debug] 위치 권한 요청 결과: $status");
    locationPermissionStatus.value = status;
    if (status.isPermanentlyDenied) {
      print("📍 [Debug] 영구 거부됨 -> 설정창 이동");
      openAppSettings();
    }
  }
}