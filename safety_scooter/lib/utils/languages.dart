import 'package:get/get.dart';

class Languages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ko_KR': {
          'settings_title': '설정',
          'language': '언어 설정',
          'ai_sensitivity': 'AI 민감도 설정',
          'confidence_desc': '정확도 임계값',
          'iou_desc': '박스 겹침 허용도',
          'save': '저장 완료',
          'danger_msg': '위험 감지! 감속하세요',
          'sensitivity_info': '값이 낮을수록(0.5) 더 민감하게 감지하고,\n값이 높을수록(1.0) 확실한 위험만 감지합니다.',
        },
        'en_US': {
          'settings_title': 'Settings',
          'language': 'Language',
          'ai_sensitivity': 'AI Sensitivity',
          'confidence_desc': 'Confidence Threshold',
          'iou_desc': 'IOU Threshold',
          'save': 'Saved',
          'danger_msg': 'DANGER DETECTED! SLOW DOWN',
          'sensitivity_info': 'Lower values (0.5) detect more sensitively,\nHigher values (1.0) detect only certain dangers.',
        },
      };
}