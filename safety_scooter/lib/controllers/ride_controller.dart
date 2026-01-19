import 'dart:async';
import 'package:get/get.dart';
import '../controllers/global_controller.dart'; // GlobalController 접근을 위해 필요
import '../screens/ride_summary_screen.dart';

class RideController extends GetxController {
  // 주행 중 상태 여부
  final RxBool isRiding = false.obs;

  final RxInt _elapsedSeconds = 0.obs;
  Timer? _timer;

  RxString get formattedTime => _formatTime(_elapsedSeconds.value).obs;
  int get currentSeconds => _elapsedSeconds.value;

  // GlobalController를 찾아서 변수에 담아둡니다.
  final GlobalController globalController = Get.find<GlobalController>();

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // 주행 시작
  void startRide() {
    isRiding.value = true;
    
    // ★ [수정] 주행 시작 시 AI 스위치 ON
    globalController.isAiEnabled.value = true;

    _elapsedSeconds.value = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds.value++;
    });
  }

  // 주행 종료
  void stopRide() {
    isRiding.value = false;
    
    // ★ [수정] 주행 종료 시 AI 스위치 OFF 및 박스 제거
    globalController.isAiEnabled.value = false;
    globalController.yoloResults.clear(); // 화면에 남은 박스 즉시 제거

    _timer?.cancel();
    // 필요하다면 결과 화면 이동 로직 (현재는 같은 화면 유지 중이면 주석 처리)
     Get.to(() => const RideSummaryScreen());
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    
    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return '$hoursStr:$minutesStr:$secondsStr';
  }
}