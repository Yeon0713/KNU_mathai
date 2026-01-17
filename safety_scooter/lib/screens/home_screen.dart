import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Ticker 사용을 위해 추가
import 'package:get/get.dart';
import '../controllers/global_controller.dart';
import '../controllers/settings_controller.dart'; 
import 'camera_view.dart';
import 'settings_screen.dart'; 

// 보간된 박스 데이터를 담을 클래스
class InterpolatedBox {
  Rect rect; // 현재 화면에 그려질 위치 (보간됨)
  final String tag;
  final double confidence;
  final int id;

  InterpolatedBox(this.rect, this.tag, this.confidence, this.id);
}

// ★ 변경 1: HomeScreen은 이제 Ticker(애니메이션)와 상관없이 상태만 관리합니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GlobalController controller;
  late SettingsController settingsController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GlobalController());
    settingsController = Get.put(SettingsController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          // [Layer 1] 배경: 카메라
          Positioned.fill(
            child: const CameraView(),
          ),

          // [Layer 1.5] ★ 최적화: 박스 그리는 부분만 별도 위젯으로 분리
          Positioned.fill(
            child: BoundingBoxOverlay(controller: controller),
          ),

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

                  // 하단 대시보드
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
}

// ★ 분리된 위젯: 여기서만 60fps로 setState가 발생하므로, 다른 UI(속도계 등)는 영향받지 않음
class BoundingBoxOverlay extends StatefulWidget {
  final GlobalController controller;
  const BoundingBoxOverlay({super.key, required this.controller});

  @override
  State<BoundingBoxOverlay> createState() => _BoundingBoxOverlayState();
}

class _BoundingBoxOverlayState extends State<BoundingBoxOverlay> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final Map<int, InterpolatedBox> _boxes = {};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    // 로직은 동일합니다. widget.controller로 접근하는 것만 다릅니다.
    if (widget.controller.yoloResults.isEmpty) {
      if (_boxes.isNotEmpty) {
        setState(() => _boxes.clear());
      }
      return;
    }

    final results = widget.controller.yoloResults;
    final Set<int> currentIds = {};
    bool needsRepaint = false;

    for (var res in results) {
      final List<dynamic> boxArr = res['box'];
      final int id = res['id'] ?? -1;
      final String tag = res['tag'];
      final double conf = (boxArr[4] as num).toDouble() * 100;
      
      final Rect targetRect = Rect.fromLTRB(
        (boxArr[0] as num).toDouble(),
        (boxArr[1] as num).toDouble(),
        (boxArr[2] as num).toDouble(),
        (boxArr[3] as num).toDouble(),
      );
      
      currentIds.add(id);

      if (_boxes.containsKey(id)) {
        final InterpolatedBox old = _boxes[id]!;
        final Rect newRect = Rect.lerp(old.rect, targetRect, 0.3)!;
        
        if (newRect != old.rect) {
          _boxes[id] = InterpolatedBox(newRect, tag, conf, id);
          needsRepaint = true;
        }
      } else {
        _boxes[id] = InterpolatedBox(targetRect, tag, conf, id);
        needsRepaint = true;
      }
    }

    final idsToRemove = _boxes.keys.where((id) => !currentIds.contains(id)).toList();
    if (idsToRemove.isNotEmpty) {
      for (var id in idsToRemove) {
        _boxes.remove(id);
      }
      needsRepaint = true;
    }

    if (needsRepaint) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BoundingBoxPainter(
        _boxes.values.toList(),
        widget.controller.camImageWidth.value,
        widget.controller.camImageHeight.value,
      ),
    );
  }
}

/// 보간된 박스 데이터를 받아 그리는 페인터
class BoundingBoxPainter extends CustomPainter {
  final List<InterpolatedBox> boxes; // 수정됨: 컨트롤러 대신 보간된 박스 리스트를 받음
  final double imgW;
  final double imgH;

  BoundingBoxPainter(this.boxes, this.imgW, this.imgH);

  @override
  void paint(Canvas canvas, Size size) {
    if (imgW == 0 || imgH == 0) return;

    // 화면 비율에 맞춰 이미지 스케일링 계산 (BoxFit.cover 로직)
    double screenRatio = size.width / size.height;
    double imageRatio = imgH / imgW; 

    double scale, offsetX, offsetY;

    if (screenRatio > imageRatio) {
      scale = size.width / imgH;
      offsetX = 0;
      offsetY = (size.height - (imgW * scale)) / 2;
    } else {
      scale = size.height / imgW;
      offsetX = (size.width - (imgH * scale)) / 2;
      offsetY = 0;
    }

    final Paint paintBox = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final Paint paintBg = Paint()
      ..style = PaintingStyle.fill;

    for (var boxData in boxes) {
      final rectRaw = boxData.rect;
      final String tag = boxData.tag;
      final double confidence = boxData.confidence;
      final int id = boxData.id;

      Color boxColor;
      if (tag == "DANGER_HIT") {
        boxColor = Colors.redAccent;
      } else if (tag == "CAUTION_OBJ") {
        boxColor = Colors.amber;
      } else {
        boxColor = Colors.greenAccent;
      }

      paintBox.color = boxColor;
      paintBg.color = boxColor.withOpacity(0.8);

      // 좌표 변환 (이미지 좌표계 -> 화면 좌표계)
      double left = rectRaw.left * scale + offsetX;
      double top = rectRaw.top * scale + offsetY;
      double width = rectRaw.width * scale;
      double height = rectRaw.height * scale;

      // 1. 박스 그리기
      Rect rect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(rect, paintBox);

      // 2. 텍스트 그리기
      String text = id != -1
          ? "[$id] $tag ${confidence.toStringAsFixed(0)}%"
          : "$tag ${confidence.toStringAsFixed(0)}%";

      TextSpan span = TextSpan(
        text: text,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );

      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      // 텍스트 배경
      canvas.drawRect(
        Rect.fromLTWH(left, top, tp.width + 8, tp.height + 4),
        paintBg,
      );

      // 텍스트
      tp.paint(canvas, Offset(left + 4, top + 2));
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    // 리스트 내용이 바뀌었거나 길이가 다르면 다시 그림
    return true; 
  }
}
