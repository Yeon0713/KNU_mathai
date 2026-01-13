import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import '../utils/notification_helper.dart'; // <--- 1. 여기 경로가 실제 파일 위치와 맞는지 꼭 확인!

class GlobalController extends GetxController {
  var speed = "0.0 km/h".obs;
  var isDanger = false.obs;

  final Battery _battery = Battery();
  var batteryLevel = 100.obs;

  // NotificationHelper 선언
  final NotificationHelper _notification = NotificationHelper();

  @override
  void onInit() {
    super.onInit();
    _notification.init(); // 초기화
    _startSpeedTracking();
    _initBatteryTracking();
  }

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

      if (kmhSpeed > 30) {
        isDanger.value = true;
        _notification.triggerWarning(0.25); // 속도가 빠르면 소리 재생
      } else {
        isDanger.value = false;
      }
    });
  }

  void _initBatteryTracking() async {
    _updateBatteryLevel();
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _updateBatteryLevel();
    });
  }

  void _updateBatteryLevel() async {
    final level = await _battery.batteryLevel;
    batteryLevel.value = level;
  }

  // 중복되지 않게 하나만 남겨둡니다.
  void setDangerStatus(bool status) {
    isDanger.value = status;
    if (status) {
      _notification.triggerWarning(0.25); // 버튼 눌러서 위험할 때 소리 재생
    }
  }

  void updateSpeed(double newSpeed) => speed.value = "$newSpeed km/h";
}