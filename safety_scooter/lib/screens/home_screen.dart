import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart'; // 관제탑 불러오기
import 'camera_view.dart'; 

class HomeScreen extends StatelessWidget { // StatefulWidget일 필요 없음 (GetX 쓰니까)
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 관제탑(Controller) 등록! 이제 어디서든 controller 변수로 접근 가능
    final controller = Get.put(GlobalController());

    return Scaffold(
      body: Stack(
        children: [
          // 1. 배경: 카메라
          const Positioned.fill(
            child: CameraView(),
          ),

          // 2. 위험 감지 시 빨간 화면 깜빡임 (Obx로 감싸서 실시간 반응)
          Obx(() => controller.isDanger.value
              ? Container(
                  color: Colors.red.withOpacity(0.5), // 위험할 때 빨간색 반투명
                  width: double.infinity,
                  height: double.infinity,
                )
              : const SizedBox()), // 안전할 땐 아무것도 없음

          // 3. UI 오버레이
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(controller), // 컨트롤러를 넘겨줌
                const Spacer(),
                _buildBottomBar(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(GlobalController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 속도계 (Obx로 감싸서 속도 바뀌면 숫자 바뀜)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Obx(() => Text(
              "🚀 ${controller.speed.value}", // 관제탑의 속도값 표시
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            )),
          ),
          
          // 상태 메시지
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: controller.isDanger.value ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              controller.isDanger.value ? "⚠️ 위험 감지!" : "✅ 안전함",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomBar(GlobalController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Center(
        child: FloatingActionButton.extended(
          onPressed: () {
            // 테스트: 버튼 누르면 강제로 위험 상태 토글
            controller.setDangerStatus(!controller.isDanger.value);
            controller.updateSpeed(controller.isDanger.value ? 25.4 : 0.0);
          },
          label: const Text("시뮬레이션 테스트"),
          icon: const Icon(Icons.bug_report),
          backgroundColor: Colors.blueAccent,
        ),
      ),
    );
  }
}