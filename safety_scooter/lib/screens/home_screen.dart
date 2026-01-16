import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';
import '../controllers/settings_controller.dart'; 
import 'camera_view.dart';
import 'settings_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. GlobalController 등록
    final controller = Get.put(GlobalController());

    // 2. SettingsController 등록 및 변수에 담기 (UI에서 쓰기 위해)
    // permanent: true로 설정하여 앱 종료 전까지 살아있게 함
    final settingsController = Get.put(SettingsController(), permanent: true);

    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          // [Layer 1] 배경: 카메라
          Positioned.fill(
            child: CameraView(),
          ),

          // [Layer 1.5] YOLO Bounding Boxes
          Obx(() {
            if (controller.yoloResults.isEmpty) return const SizedBox();
            final Size screenSize = MediaQuery.of(context).size;
            return Stack(
              children: _renderBoxes(controller, screenSize),
            );
          }),

          // [Layer 2] 시인성 강화 그라데이션
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

          // [Layer 3] 위험 감지 시 붉은 테두리
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

          // [Layer 4] HUD 정보 표시
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.electric_scooter, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        "Safety Scooter",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                      ),
                      
                      const Spacer(),

                      // ★ [추가됨] 현재 AI 민감도 표시 박스
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
                            // 실시간으로 변하는 민감도 값 표시
                            Obx(() => Text(
                              "AI: ${settingsController.confThreshold.value.toStringAsFixed(2)}", 
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            )),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8), // 아이콘 사이 간격

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
                  ),
                  
                  const Spacer(), 

                  // 중앙 하단: 위험 경고 메시지
                  Obx(() => controller.isDanger.value
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
                      : const SizedBox()),

                  // 하단 대시보드 (속도계 + 설정 버튼)
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
                      
                      // 설정 버튼
                      FloatingActionButton(
                        onPressed: () {
                          Get.to(() => const SettingsScreen());
                        },
                        backgroundColor: Colors.grey[800],
                        child: const Icon(Icons.settings, color: Colors.white),
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

  List<Widget> _renderBoxes(GlobalController controller, Size screen) {
    if (controller.camImageHeight.value == 0 || controller.camImageWidth.value == 0) {
      return [];
    }

    double imgH = controller.camImageHeight.value; 
    double imgW = controller.camImageWidth.value;  

    double screenRatio = screen.width / screen.height;
    double imageRatio = imgH / imgW; 

    double scale, offsetX, offsetY;

    if (screenRatio > imageRatio) {
      scale = screen.width / imgH;
      offsetX = 0;
      offsetY = (screen.height - (imgW * scale)) / 2; 
    } else {
      scale = screen.height / imgW;
      offsetX = (screen.width - (imgH * scale)) / 2;
      offsetY = 0;
    }

    return controller.yoloResults.map((result) {
      final box = result["box"]; 
      final String tag = result["tag"];
      final double confidence = (box[4] * 100);

      Color boxColor;
      if (tag == "DANGER_HIT") {
        boxColor = Colors.redAccent;
      } else if (tag == "CAUTION_OBJ") {
        boxColor = Colors.amber;
      } else {
        boxColor = Colors.greenAccent;
      }

      double left = box[0] * scale + offsetX;
      double top = box[1] * scale + offsetY;
      double width = (box[2] - box[0]) * scale;
      double height = (box[3] - box[1]) * scale;

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: boxColor, width: 2.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              color: boxColor.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                "$tag ${confidence.toStringAsFixed(0)}%",
                style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}