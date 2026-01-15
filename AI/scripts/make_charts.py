from ultralytics import YOLO
import os

# 학습된 모델 경로 (본인 경로 확인!)
model_path = 'Kickboard_AI/m2_safety_s_v1/weights/best.pt'

if os.path.exists(model_path):
    model = YOLO(model_path)
    
    # 검증 실행 (이 과정에서 confusion_matrix 등이 생성됨)
    # plots=True 옵션이 그래프를 그려주는 핵심입니다.
    metrics = model.val(data='road.yaml', plots=True, split='val')
    
    print("\n✅ 그래프 생성 완료! 'runs/detect/val' 폴더를 확인해보세요.")
else:
    print(f"❌ 모델 파일이 없습니다: {model_path}"