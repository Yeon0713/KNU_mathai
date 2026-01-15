import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safety_scooter/screens/camera_view.dart';
import '../controllers/global_controller.dart';
import 'camera_view.dart';
import 'settings_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GlobalController());

    return Scaffold(
      backgroundColor: Colors.black, // 카메라 로딩 전 검은색
      body: Stack(
        children: [
          // [Layer 1] 배경: 카메라 
          Positioned.fill(
            child: CameraView(),
          ),

          // [Layer 1.5] YOLO Bounding Boxes (AI 인식 박스 그리기)
          // Controller의 yoloResults가 변할 때마다 화면을 다시 그림
          Obx(() {
            if (controller.yoloResults.isEmpty) return const SizedBox();
            
            // 화면 크기 가져오기
            final Size screenSize = MediaQuery.of(context).size;
            
            // 박스 그리기 함수 호출
            return Stack(
              children: _renderBoxes(controller, screenSize),
            );
          }),

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
                  Row( 
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

                  // 중앙 하단: 위험 경고 메시지 (조건부 표시)
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
                          // 설정 화면으로 이동
                          Get.to(() => const SettingsScreen());
                        },
                        backgroundColor: Colors.grey[800], 
                        elevation: 2, 
                        mini: false,  
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
    // 1. 카메라 이미지 크기가 아직 없으면 빈 리스트 반환
    if (controller.camImageHeight.value == 0 || controller.camImageWidth.value == 0) {
      return [];
    }

    // 2. 화면 비율과 이미지 비율 계산 (좌표 밀림 방지)
    // 안드로이드는 이미지가 90도 돌아가 있으므로 Width/Height를 바꿔서 생각해야 함
    double imgH = controller.camImageHeight.value; 
    double imgW = controller.camImageWidth.value;  

    // 화면이 이미지를 꽉 채울 때(BoxFit.cover)의 스케일과 오차(Offset) 계산
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
      final box = result["box"]; // [x1, y1, x2, y2, confidence]
      final String tag = result["tag"];
      final double confidence = (box[4] * 100);

      // -----------------------------------------------------------
      // [핵심 수정 1] 라벨 이름 변경 (labels.txt 기준)
      // DANGER_HIT -> 빨간색 (위험)
      // 그 외 -> 초록색 (안전/기타)
      // -----------------------------------------------------------
      Color boxColor;
      if (tag == "DANGER_HIT") {
        boxColor = Colors.redAccent;
      } else if (tag == "CAUTION_OBJ") {
        boxColor = Colors.amber;
      } else {
        boxColor = Colors.greenAccent;
      }

      // -----------------------------------------------------------
      // [핵심 수정 2] 좌표 변환 (Scale + Offset)
      // -----------------------------------------------------------
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
                // 태그 이름과 정확도 표시
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