import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';
import '../controllers/settings_controller.dart';
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
            const Spacer(),
            _buildDangerMessage(),
            _buildBottomDashboard(),
          ],
        ),
      ),
    );
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
        // AI 민감도 표시
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.remove_red_eye, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 4),
              Obx(() => Text(
                "AI: ${settingsController.confThreshold.value.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
        FloatingActionButton(
          onPressed: () {
            Get.to(() => const SettingsScreen());
          },
          backgroundColor: Colors.grey[800],
          child: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }
}