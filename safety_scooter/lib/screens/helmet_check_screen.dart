import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';
import 'camera_view.dart';
import 'home_screen.dart';

class HelmetCheckScreen extends StatefulWidget {
  const HelmetCheckScreen({super.key});

  @override
  State<HelmetCheckScreen> createState() => _HelmetCheckScreenState();
}

class _HelmetCheckScreenState extends State<HelmetCheckScreen> {
  // [수정] 화면이 넘어가도 컨트롤러가 죽지 않도록 permanent: true 설정
  final GlobalController controller = Get.put(GlobalController(), permanent: true);

  @override
  void initState() {
    super.initState();
    // 헬멧 모드 진입
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.startHelmetCheckMode();
    });

    // [추가] 헬멧 감지 성공 시 홈 화면으로 자동 이동
    ever(controller.isHelmetDetected, (bool isDetected) {
      if (isDetected) {
        // "확인되었습니다" 메시지와 아이콘을 볼 수 있게 1.5초 딜레이 후 이동
        Future.delayed(const Duration(milliseconds: 1500), () {
          Get.off(() => const HomeScreen());
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 계산 (프레임 위치 잡기용)
    final double frameWidth = 280;
    final double frameHeight = 350;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 카메라 뷰 (전체 화면)
          const Positioned.fill(
            child: CameraView(),
          ),

          // 2. 어두운 배경 오버레이 (가운데 뚫린 효과)
          _buildDarkOverlay(frameWidth, frameHeight),

          // 3. 중앙 고정 프레임
          Center(
            child: Obx(() {
              bool isDetected = controller.isHelmetDetected.value;
              return SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: Stack(
                  children: [
                    // 정적 테두리
                    CustomPaint(
                      painter: ScannerBorderPainter(
                        color: isDetected ? Colors.greenAccent : Colors.cyanAccent,
                      ),
                      child: Container(),
                    ),
                    
                    // 감지 성공 시 아이콘 표시
                    if (isDetected)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.greenAccent, width: 2),
                          ),
                          child: const Icon(Icons.check, color: Colors.greenAccent, size: 48),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          // 4. UI 텍스트 및 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  Column(
                    children: [
                      const Text(
                        "HELMET CHECK",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Obx(() => Text(
                        controller.isHelmetDetected.value 
                            ? "확인되었습니다." 
                            : "프레임 안에 얼굴을 맞춰주세요.",
                        style: const TextStyle(
                          color: Colors.white70, 
                          fontSize: 15,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      )),
                    ],
                  ),

                  const Spacer(),

                  // 강제 통과 버튼 (테스트용)
                  TextButton(
                    onPressed: () {
                      Get.off(() => const HomeScreen());
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white38,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Skip Test Mode", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkOverlay(double w, double h) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerBorderPainter extends CustomPainter {
  final Color color;
  ScannerBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    double w = size.width;
    double h = size.height;
    double cornerSize = 40.0;

    Path path = Path();
    // 좌상
    path.moveTo(0, cornerSize); path.lineTo(0, 0); path.lineTo(cornerSize, 0);
    // 우상
    path.moveTo(w - cornerSize, 0); path.lineTo(w, 0); path.lineTo(w, cornerSize);
    // 우하
    path.moveTo(w, h - cornerSize); path.lineTo(w, h); path.lineTo(w - cornerSize, h);
    // 좌하
    path.moveTo(cornerSize, h); path.lineTo(0, h); path.lineTo(0, h - cornerSize);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}