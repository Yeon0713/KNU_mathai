import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/ride_controller.dart';
import '../screens/settings_screen.dart';

class DashboardOverlay extends StatelessWidget {
  final GlobalController controller;
  final SettingsController settingsController;

  const DashboardOverlay({
    super.key,
    required this.controller,
    required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            _buildDebugPanel(), // [추가] 디버그 패널
            const Spacer(),
            _buildDangerMessage(),
            _buildBottomDashboard(),
          ],
        ),
      ),
    );
  }

  // [추가] 디버그 패널 위젯
  Widget _buildDebugPanel() {
    return Obx(() {
      if (!controller.isDebugOverlayOpen.value) return const SizedBox();
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🛠 디버그 모드", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Obx(() => Text("위도 (Lat): ${controller.sensorService.latitude.value.toStringAsFixed(7)}", 
                style: const TextStyle(color: Colors.greenAccent, fontFamily: "monospace"))),
            const SizedBox(height: 4),
            Obx(() => Text("경도 (Lng): ${controller.sensorService.longitude.value.toStringAsFixed(7)}", 
                style: const TextStyle(color: Colors.greenAccent, fontFamily: "monospace"))),
            
            const SizedBox(height: 8),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),

            // [추가] AI 성능 및 센서 데이터
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text("FPS: ${controller.fps.value.toStringAsFixed(1)}", style: const TextStyle(color: Colors.amberAccent))),
                Obx(() => Text("Objects: ${controller.objCount.value}", style: const TextStyle(color: Colors.amberAccent))),
              ],
            ),
            Obx(() => Text("Vibration: ${controller.sensorService.rawVibration.value.toStringAsFixed(2)}", 
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
            const SizedBox(height: 4),
            Obx(() => Text("Server: ${controller.lastServerResponse.value}", 
                style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12))),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.sendDebugReport(),
                icon: const Icon(Icons.send, size: 16),
                label: const Text("현재 상태 리포트 전송"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Icon(Icons.electric_scooter, color: Colors.white, size: 28),
        const SizedBox(width: 8),
        const Text(
          "Safety Scooter",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.0),
        ),
        const Spacer(),
        
        // [추가] GPS 상태 표시 인디케이터
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Obx(() => Icon(
                Icons.location_on, 
                color: controller.sensorService.isGpsReady.value ? Colors.greenAccent : Colors.redAccent, 
                size: 16
              )),
            ],
          ),
        ),
        
        const SizedBox(width: 8),
        // 배터리 아이콘
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.battery_std, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 4),
              Obx(() => Text(
                "${controller.batteryLevel.value}%",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              )),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDangerMessage() {
    return Obx(() => controller.isDanger.value
        ? Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 20, spreadRadius: 2)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    "danger_msg".tr,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox());
  }

  Widget _buildBottomDashboard() {
    final RideController rideController = Get.find<RideController>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("CURRENT SPEED", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Obx(() => Text(
                  controller.speed.value.split(' ')[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                )),
                const SizedBox(width: 8),
                const Text("km/h", style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const Spacer(),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [디버깅] 서버 테스트 버튼 (작게 유지)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: "test_btn",
                    // [수정] 버튼 클릭 시 디버그 오버레이 토글
                    onPressed: () => controller.isDebugOverlayOpen.toggle(),
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    mini: true,
                    child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                // 설정 버튼 (작게 변경하여 균형 맞춤)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: "settings_btn",
                    onPressed: () => Get.to(() => const SettingsScreen()),
                    backgroundColor: Colors.grey[800],
                    mini: true,
                    child: const Icon(Icons.settings, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // [주행] 시작/종료 버튼 (메인 액션)
            Obx(() => FloatingActionButton.extended(
                  heroTag: "ride_btn",
                  onPressed: () => rideController.isRiding.value ? rideController.stopRide() : rideController.startRide(),
                  backgroundColor: rideController.isRiding.value ? Colors.red : Colors.green,
                  icon: Icon(rideController.isRiding.value ? Icons.stop : Icons.play_arrow, color: Colors.white),
                  label: Text(rideController.isRiding.value ? "주행 종료" : "주행 시작", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                )),
          ],
        ),
      ],
    );
  }
}