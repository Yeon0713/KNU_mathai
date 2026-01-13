import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart'; // 1. 패키지 추가 확인

class GlobalController extends GetxController {
  // --- 공통 변수 ---
  var speed = "0.0 km/h".obs;
  var isDanger = false.obs;

  // --- 배터리 관련 변수 추가 ---
  final Battery _battery = Battery();
  var batteryLevel = 100.obs;

  @override
  void onInit() {
    super.onInit();
    _startSpeedTracking(); // GPS 추적 시작
    _initBatteryTracking(); // 배터리 추적 시작 (추가)
  }

  // 1. GPS 속도 추적 로직 (기존 유지)
  void _startSpeedTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      double kmhSpeed = position.speed * 3.6;
      speed.value = "${kmhSpeed.toStringAsFixed(1)} km/h";

      if (kmhSpeed > 20) {
        isDanger.value = true;
      } else {
        isDanger.value = false;
      }
    });
  }

  // 2. 배터리 추적 로직 (새로 추가)
  void _initBatteryTracking() async {
    // 앱 시작 시 첫 배터리 수치 가져오기
    _updateBatteryLevel();

    // 배터리 상태(충전 중/방전 중)가 바뀔 때마다 수치 갱신
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _updateBatteryLevel();
    });
  }

  void _updateBatteryLevel() async {
    final level = await _battery.batteryLevel;
    batteryLevel.value = level;
  }

  // 기존 함수 유지
  void setDangerStatus(bool status) => isDanger.value = status;
  void updateSpeed(double newSpeed) => speed.value = "$newSpeed km/h";
}