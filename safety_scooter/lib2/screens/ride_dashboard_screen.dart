import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../main.dart'; // cameras 변수 접근용
import '../controllers/ride_controller.dart';
import 'ride_summary_screen.dart';

class RideDashboardScreen extends StatefulWidget {
  const RideDashboardScreen({super.key});

  @override
  State<RideDashboardScreen> createState() => _RideDashboardScreenState();
}

class _RideDashboardScreenState extends State<RideDashboardScreen> {
  CameraController? controller;
  final RideController rideController = Get.find<RideController>(); // 컨트롤러 찾기

  @override
  void initState() {
    super.initState();
    // 카메라 초기화 로직
    if (cameras.isNotEmpty) {
      controller = CameraController(cameras[0], ResolutionPreset.high);
      controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar 없이 전체 화면 사용
      body: Stack(
        children: [
          // 1. 배경: 카메라 프리뷰
          if (controller != null && controller!.value.isInitialized)
            SizedBox.expand(
              child: CameraPreview(controller!),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // 2. 상단: 주행 시간 표시 (GetX Obx 사용)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Obx(() => Text(
                      rideController.formattedTime.value, // 실시간 시간 업데이트
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()], // 숫자 간격 고정
                      ),
                    )),
              ),
            ),
          ),

          // 3. 하단: 주행 종료 버튼
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                rideController.stopRide(); // 타이머 정지
                // 종료 화면으로 이동 (뒤로 가기 방지: off)
                Get.off(() => const RideSummaryScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                '주행 종료',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}