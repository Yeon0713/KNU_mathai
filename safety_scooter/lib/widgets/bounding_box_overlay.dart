import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../controllers/global_controller.dart';

// 보간된 박스 데이터를 담을 클래스
class InterpolatedBox {
  Rect rect; // 현재 화면에 그려질 위치 (보간됨)
  final String tag;
  final double confidence;
  final int id;

  InterpolatedBox(this.rect, this.tag, this.confidence, this.id);
}

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

class BoundingBoxPainter extends CustomPainter {
  final List<InterpolatedBox> boxes;
  final double imgW;
  final double imgH;

  BoundingBoxPainter(this.boxes, this.imgW, this.imgH);

  @override
  void paint(Canvas canvas, Size size) {
    if (imgW == 0 || imgH == 0) return;

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

      double left = rectRaw.left * scale + offsetX;
      double top = rectRaw.top * scale + offsetY;
      double width = rectRaw.width * scale;
      double height = rectRaw.height * scale;

      Rect rect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(rect, paintBox);

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

      canvas.drawRect(
        Rect.fromLTWH(left, top, tp.width + 8, tp.height + 4),
        paintBg,
      );

      tp.paint(canvas, Offset(left + 4, top + 2));
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return true; 
  }
}