import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';
import '../controllers/ride_controller.dart';
import '../controllers/settings_controller.dart';
import 'camera_view.dart';
import 'settings_screen.dart'; // 설정 화면 import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // GlobalController 찾기
  final GlobalController controller = Get.find<GlobalController>();

  @override
  void initState() {
    super.initState();
    // 화면이 켜지면 안전하게 '대시보드 모드(후면 카메라)'로 전환
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.startDashboardMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 필요한 컨트롤러들 등록
    final rideController = Get.put(RideController());
    final settingsController = Get.put(SettingsController(), permanent: true);
    controller.setRideController(rideController);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ------------------------------------------------
          // 1. 배경: 카메라 뷰
          // ------------------------------------------------
          const Positioned.fill(
            child: CameraView(),
          ),

          // ------------------------------------------------
          // 2. 오버레이: YOLO 박스 그리기
          // ------------------------------------------------
          // ------------------------------------------------
          // 2. 오버레이: YOLO 박스 그리기
          // ------------------------------------------------
          Obx(() {
            // ★ [추가된 코드] 주행 중이 아니면 박스를 아예 안 그림
            if (!rideController.isRiding.value) {
              return const SizedBox();
            }

            // 카메라가 초기화 안 됐거나, 결과가 없으면 빈 화면
            if (!controller.isCameraInitialized.value || controller.yoloResults.isEmpty) {
              return const SizedBox();
            }
            final Size screenSize = MediaQuery.of(context).size;
            return Stack(
              children: _renderBoxes(controller, screenSize),
            );
          }),

          // ------------------------------------------------
          // 3. UI 효과: 상하단 그라데이션 (텍스트 가독성용)
          // ------------------------------------------------
          Column(
            children: [
              Container(
                height: 120,
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

          // ------------------------------------------------
          // 4. 경고 효과: 위험 감지 시 빨간 테두리 깜빡임
          // ------------------------------------------------
          Obx(() => (controller.isDanger.value && rideController.isRiding.value) // ★ 여기 조건 수정됨
              ? IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.redAccent, width: 8),
                      color: Colors.red.withOpacity(0.2),
                    ),
                  ),
                )
              : const SizedBox()),

          // ------------------------------------------------
          // 5. 메인 정보 UI (속도, 배터리, 버튼 등)
          // ------------------------------------------------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // [상단] 설정 버튼 - 속도계 - 배터리
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 설정 버튼
                      IconButton(
                        onPressed: () {
                          // 설정 화면으로 이동
                          Get.to(() => const SettingsScreen());
                        },
                        icon: const Icon(Icons.settings, color: Colors.white, size: 32),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // 중앙 속도계 (가장 크게)
                      Column(
                        children: [
                          Obx(() => Text(
                                controller.speed.value.split(' ')[0], // 숫자만 표시
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              )),
                          const Text(
                            "km/h",
                            style: TextStyle(color: Colors.white70, fontSize: 18),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // 배터리 아이콘
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Obx(() => Icon(
                                  controller.batteryLevel.value > 20 
                                      ? Icons.battery_full 
                                      : Icons.battery_alert,
                                  color: controller.batteryLevel.value > 20 
                                      ? Colors.greenAccent 
                                      : Colors.redAccent,
                                )),
                            const SizedBox(width: 4),
                            Obx(() => Text(
                                  "${controller.batteryLevel.value}%",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(), // 중간 여백

                  // [하단] 주행 타이머 & 버튼 & AI 정보
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Obx(() => Text(
                                  "AI 민감도: ${settingsController.confThreshold.value.toStringAsFixed(1)}",
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                )),
                          ),
                          const SizedBox(height: 4),
                          
                          // ★ [수정된 부분] 주행 상태에 따라 문구와 색상 변경
                          Obx(() => Text(
                            rideController.isRiding.value ? "객체 탐지 중..." : "주행 대기 중",
                            style: TextStyle(
                              // 주행 중이면 초록색, 아니면 회색
                              color: rideController.isRiding.value ? Colors.greenAccent : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ],
                      ),

                      // 2. 주행 타이머 (중앙, 주행 중일 때만 표시)
                      Obx(() => rideController.isRiding.value
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.redAccent, width: 1.5),
                              ),
                              child: Text(
                                rideController.formattedTime.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [FontFeature.tabularFigures()], // 숫자 너비 고정
                                ),
                              ),
                            )
                          : const SizedBox()),

                      // 3. 주행 시작/종료 버튼 (오른쪽)
                      Obx(() {
                        bool isRiding = rideController.isRiding.value;
                        return ElevatedButton.icon(
                          onPressed: () {
                            if (isRiding) {
                              rideController.stopRide();
                            } else {
                              rideController.startRide();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRiding ? Colors.redAccent : Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: Icon(isRiding ? Icons.stop : Icons.play_arrow, color: Colors.white),
                          label: Text(
                            isRiding ? "종료" : "주행",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------
  // YOLO 박스 그리는 로직 (수정된 변수 적용됨)
  // ------------------------------------------------
  List<Widget> _renderBoxes(GlobalController controller, Size screen) {
    if (controller.camImageHeight.value == 0 || controller.camImageWidth.value == 0) return [];
    
    double imgH = controller.camImageHeight.value;
    double imgW = controller.camImageWidth.value;
    
    // 화면 비율에 맞춰 스케일 계산 (Contain 대신 Cover 비율로 계산)
    double scale = screen.width / imgH > screen.height / imgW 
        ? screen.width / imgH 
        : screen.height / imgW;
        
    double offsetX = (screen.width - imgH * scale) / 2;
    double offsetY = (screen.height - imgW * scale) / 2;

    // 가로/세로 모드 보정 (일반적인 세로모드 기준)
    if (screen.width / screen.height > imgH / imgW) {
        scale = screen.width / imgH;
        offsetX = 0;
        offsetY = (screen.height - (imgW * scale)) / 2;
    }

    return controller.yoloResults.map((result) {
      final box = result["box"]; 
      final String tag = result["tag"];
      final double confidence = (box[4] * 100);

      // 위험 객체는 빨간색, 나머지는 초록색
      Color boxColor = Colors.greenAccent;
      if (tag == "person" || tag == "car" || tag == "truck" || tag == "DANGER_HIT") {
         boxColor = Colors.redAccent;
      }

      // 좌표 계산
      double left = box[0] * scale + offsetX;
      double top = box[1] * scale + offsetY;
      double width = (box[2] - box[0]) * scale;
      double height = (box[3] - box[1]) * scale;

      return Positioned(
        left: left, top: top, width: width, height: height,
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
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}