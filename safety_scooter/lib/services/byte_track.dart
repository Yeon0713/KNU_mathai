import 'dart:math';

/// ByteTrack 알고리즘을 구현한 트래커 클래스
class ByteTracker {
  List<STrack> trackedStracks = [];
  List<STrack> lostStracks = [];
  List<STrack> removedStracks = [];

  int frameId = 0;
  int maxTimeLost = 30; // 객체가 사라져도 유지할 프레임 수
  int _trackIdCount = 0;

  ByteTracker();

  /// 매 프레임마다 호출하여 트래킹 상태를 업데이트합니다.
  List<Map<String, dynamic>> update(List<Map<String, dynamic>> results, double confThreshold) {
    frameId++;

    // 1. Detection 분류 (High Score / Low Score)
    List<STrack> detections = [];
    List<STrack> detectionsLow = [];

    for (var res in results) {
      final box = res['box']; // [x1, y1, x2, y2, conf]
      double score = box[4];
      String tag = res['tag'];
      
      // [x, y, w, h] 형태로 변환
      List<double> tlwh = [box[0], box[1], box[2] - box[0], box[3] - box[1]];

      STrack t = STrack(tlwh, score, tag);
      if (score >= confThreshold) {
        detections.add(t);
      } else if (score > 0.1) { // 낮은 점수라도 0.1 이상이면 후보군으로 둠
        detectionsLow.add(t);
      }
    }

    // 2. 기존 트랙들의 위치 예측 (Simplified Kalman Prediction)
    List<STrack> strackPool = [...trackedStracks, ...lostStracks];
    for (var t in strackPool) {
      t.predict();
    }

    // 3. 1차 매칭: High Score Detections <-> Existing Tracks
    // IoU Threshold 0.5 (이동 중인 카메라이므로 기준 완화: 0.8 -> 0.5)
    var firstMatches = _associate(strackPool, detections, 0.5);

    for (var match in firstMatches.matches) {
      match.track.update(match.detection, frameId);
    }

    // 4. 2차 매칭: Low Score Detections <-> Remaining Tracks
    // 1차에서 매칭되지 않은 트랙들과 낮은 점수의 디텍션을 매칭 (IoU 0.5 -> 0.3)
    var remainingTracks = firstMatches.unmatchedTracks
        .where((t) => t.state == TrackState.tracked).toList();

    var secondMatches = _associate(remainingTracks, detectionsLow, 0.3);

    for (var match in secondMatches.matches) {
      match.track.update(match.detection, frameId);
    }

    // 5. 신규 트랙 생성 (1차 매칭 실패한 High Score Detection)
    for (var det in firstMatches.unmatchedDetections) {
      _initTrack(det);
    }

    // 6. Lost 처리 (2차 매칭에서도 실패한 트랙)
    for (var t in secondMatches.unmatchedTracks) {
      if (t.state != TrackState.lost) {
        t.markLost(frameId);
        lostStracks.add(t);
      }
    }

    // 7. 리스트 정리
    trackedStracks = strackPool.where((t) => t.state == TrackState.tracked).toList();
    // 신규 생성된 트랙 추가
    trackedStracks.addAll(firstMatches.unmatchedDetections.where((t) => t.state == TrackState.tracked));

    // 너무 오래된 Lost 트랙 제거
    lostStracks.removeWhere((t) => frameId - t.frameId > maxTimeLost);

    // 결과 반환 포맷 생성
    List<Map<String, dynamic>> output = [];
    for (var t in trackedStracks) {
      if (!t.isActivated) continue;
      output.add({
        'box': [t.tlwh[0], t.tlwh[1], t.tlwh[0] + t.tlwh[2], t.tlwh[1] + t.tlwh[3], t.score],
        'tag': t.tag,
        'id': t.trackId, // 추적 ID 추가
      });
    }
    return output;
  }

  /// 추론 없이 예측만 수행 (프레임 스킵 시 사용)
  List<Map<String, dynamic>> updateWithoutDetection() {
    frameId++;

    // 모든 트랙(활성 + 분실) 위치 예측 (Kalman Prediction)
    List<STrack> strackPool = [...trackedStracks, ...lostStracks];
    for (var t in strackPool) {
      t.predict();
    }

    // 결과 반환 (활성 트랙만)
    List<Map<String, dynamic>> output = [];
    for (var t in trackedStracks) {
      if (!t.isActivated) continue;
      output.add({
        'box': [t.tlwh[0], t.tlwh[1], t.tlwh[0] + t.tlwh[2], t.tlwh[1] + t.tlwh[3], t.score],
        'tag': t.tag,
        'id': t.trackId,
      });
    }
    return output;
  }

  void _initTrack(STrack det) {
    det.activate(frameId, ++_trackIdCount);
    trackedStracks.add(det);
  }

  // Greedy IoU Matching (간소화된 매칭 로직)
  _MatchResult _associate(List<STrack> tracks, List<STrack> detections, double iouThresh) {
    List<_Match> matches = [];
    List<STrack> unmatchedTracks = [];
    List<STrack> unmatchedDetections = [...detections];

    for (var t in tracks) {
      double bestIoU = 0.0;
      STrack? bestDet;

      for (var d in unmatchedDetections) {
        double iou = _calculateIoU(t.tlwh, d.tlwh);
        if (iou > bestIoU) {
          bestIoU = iou;
          bestDet = d;
        }
      }

      if (bestIoU > iouThresh && bestDet != null) {
        matches.add(_Match(t, bestDet));
        unmatchedDetections.remove(bestDet);
      } else {
        unmatchedTracks.add(t);
      }
    }
    return _MatchResult(matches, unmatchedTracks, unmatchedDetections);
  }

  double _calculateIoU(List<double> boxA, List<double> boxB) {
    double xA = max(boxA[0], boxB[0]);
    double yA = max(boxA[1], boxB[1]);
    double xB = min(boxA[0] + boxA[2], boxB[0] + boxB[2]);
    double yB = min(boxA[1] + boxA[3], boxB[1] + boxB[3]);

    double interArea = max(0, xB - xA) * max(0, yB - yA);
    double boxAArea = boxA[2] * boxA[3];
    double boxBArea = boxB[2] * boxB[3];

    return interArea / (boxAArea + boxBArea - interArea);
  }
}

enum TrackState { newTrack, tracked, lost, removed }

class STrack {
  List<double> tlwh; // [x, y, w, h]
  double score;
  String tag;
  int trackId = 0;
  TrackState state = TrackState.newTrack;
  bool isActivated = false;
  int frameId = 0;
  
  // 속도 벡터 [vx, vy] (간이 Kalman Filter 역할)
  List<double> velocity = [0.0, 0.0];

  STrack(this.tlwh, this.score, this.tag);

  void predict() {
    if (state != TrackState.newTrack) {
      tlwh[0] += velocity[0];
      tlwh[1] += velocity[1];
    }
  }

  void activate(int frameId, int id) {
    this.trackId = id;
    this.frameId = frameId;
    this.state = TrackState.tracked;
    this.isActivated = true;
  }

  void update(STrack newTrack, int frameId) {
    this.frameId = frameId;
    this.score = newTrack.score;
    this.state = TrackState.tracked;
    this.isActivated = true;

    // 속도 업데이트 (Alpha Filter)
    // 예측 위치(this.tlwh)와 실제 측정 위치(newTrack.tlwh)의 차이를 보정하여 실제 속도 추정
    // (기존 속도 + 위치 오차)가 이번 프레임의 실제 이동량이 됨
    double realVx = (newTrack.tlwh[0] - this.tlwh[0]) + this.velocity[0];
    double realVy = (newTrack.tlwh[1] - this.tlwh[1]) + this.velocity[1];

    this.velocity[0] = 0.7 * this.velocity[0] + 0.3 * realVx;
    this.velocity[1] = 0.7 * this.velocity[1] + 0.3 * realVy;

    this.tlwh = newTrack.tlwh;
  }

  void markLost(int frameId) {
    this.state = TrackState.lost;
    this.frameId = frameId;
  }
}

class _Match {
  STrack track;
  STrack detection;
  _Match(this.track, this.detection);
}

class _MatchResult {
  List<_Match> matches;
  List<STrack> unmatchedTracks;
  List<STrack> unmatchedDetections;
  _MatchResult(this.matches, this.unmatchedTracks, this.unmatchedDetections);
}
