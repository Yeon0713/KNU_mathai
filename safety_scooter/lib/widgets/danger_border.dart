import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';

class DangerBorder extends StatelessWidget {
  final GlobalController controller;
  const DangerBorder({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.isDanger.value
        ? IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 8),
                color: Colors.red.withOpacity(0.2),
              ),
            ),
          )
        : const SizedBox());
  }
}