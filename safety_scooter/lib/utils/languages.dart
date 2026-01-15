import 'package:get/get.dart';

class Languages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ko_KR': {
          'settings_title': '설정',
          'language': '언어 설정',
          'ai_sensitivity': 'AI 민감도 설정',
          'confidence_desc': '정확도 임계값 (낮을수록 더 많이 탐지)',
          'iou_desc': '박스 겹침 허용도 (높을수록 겹친 박스 허용)',
          'save': '저장 완료',
          'danger_msg': '위험 감지! 감속하세요',
        },
        'en_US': {
          'settings_title': 'Settings',
          'language': 'Language',
          'ai_sensitivity': 'AI Sensitivity',
          'confidence_desc': 'Confidence Threshold',
          'iou_desc': 'IOU Threshold',
          'save': 'Saved',
          'danger_msg': 'DANGER DETECTED! SLOW DOWN',
        },
      };
}