import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safety_scooter/screens/camera_view.dart';
import '../controllers/global_controller.dart';
import 'camera_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GlobalController());

    return Scaffold(
      backgroundColor: Colors.black, // 카메라 로딩 전 검은색
      body: Stack(
        children: [
          // [Layer 1] 배경: 카메라 (팀원 C 영역)
          Positioned.fill(
            child: CameraView(),
          ),

          // [Layer 2] 시인성 강화 그라데이션 (위, 아래 어둡게)
          Column(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),

          // [Layer 3] 위험 감지 시 화면 테두리 붉은 점멸 효과
          Obx(() => controller.isDanger.value
              ? IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.redAccent, width: 8),
                      color: Colors.red.withOpacity(0.2),
                    ),
                  ),
                )
              : const SizedBox()),

          // [Layer 4] HUD 정보 표시 (UI)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row( // 1. 여기서 const가 있었다면 반드시 삭제하세요!
                    children: [
                      const Icon(Icons.electric_scooter, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        "Safety Scooter",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                      ),
                      const Spacer(),
                      // 배터리 아이콘
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row( // 2. 여기 child 앞의 const도 삭제하세요!
                          children: [
                            const Icon(Icons.battery_std, color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 4),
                            // 3. 고정된 "85%" 대신 아래 Obx 코드를 넣으세요.
                            Obx(() => Text(
                              "${controller.batteryLevel.value}%", 
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            )),
                          ],
                        ),
                      )
                    ],
                  ),
                  
                  const Spacer(), // 중앙 비우기

                  // 중앙 하단: 위험 경고 메시지 (조건부 표시)
                  Obx(() => controller.isDanger.value
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F), // 진한 빨강
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 20, spreadRadius: 2)
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
                                SizedBox(width: 10),
                                Text(
                                  "위험 감지! 감속하세요",
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox()),

                  // 하단 대시보드 (속도계)
                  Row(
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
                                // "0.0 km/h"에서 숫자만 파싱
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
                      
                      // 시뮬레이션 버튼 (디자인에 통합)
                      FloatingActionButton(
                        onPressed: () {
                          // 버튼 누르면 위험 상황 <-> 안전 상황 전환
                          controller.setDangerStatus(!controller.isDanger.value);
                          controller.updateSpeed(controller.isDanger.value ? 12.5 : 24.8);
                        },
                        backgroundColor: Colors.white12,
                        elevation: 0,
                        mini: true,
                        child: const Icon(Icons.bug_report, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}