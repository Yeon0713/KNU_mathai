import 'package:get/get.dart';

class GlobalController extends GetxController {
  // 1. 관측 변수 (팀원들이 이 값을 바꿀 예정)
  // .obs를 붙이면 "이 값이 바뀌면 화면도 자동으로 바껴라!"라는 뜻입니다.
  RxString speed = '0.0 km/h'.obs;     // 속도 (팀원 A 구역)
  RxBool isDanger = false.obs;         // 위험 여부 (팀원 B 구역)
  
  // 2. 속도 업데이트 함수 (팀원 A가 호출할 함수)
  void updateSpeed(double speedValue) {
    // 소수점 1자리까지만 보여주기
    speed.value = '${speedValue.toStringAsFixed(1)} km/h';
  }

  // 3. 위험 상태 변경 함수 (팀원 B가 호출할 함수)
  void setDangerStatus(bool status) {
    isDanger.value = status;
    // 위험하면 로그 찍어보기
    if (status) {
      print("🚨 위험 감지! UI 경고 작동!");
    }
  }
}