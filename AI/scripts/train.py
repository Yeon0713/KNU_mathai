import os
from ultralytics import YOLO

# WandB 비활성화 (터미널 로그에 집중하고 리소스 절약)
os.environ["WANDB_MODE"] = "disabled"

def train_kickboard_model():
    # 1. 모델 로드 (M2 에어에서는 성능/속도 밸런스가 좋은 's' 모델 추천)
    model = YOLO('yolo11s.pt')

    # 2. 학습 실행
    model.train(
        data='road.yaml',      # Train/Val 경로가 담긴 설정 파일
        epochs=50,             # 학습 횟수
        imgsz=640,             # 이미지 해상도
        batch=16,              # M2 메모리 부족 시 8로 낮추세요
        device='mps',          # 맥북 M2 GPU 가속
        project='Kickboard_AI',
        name='m2_safety_s_v1',
        exist_ok=True,
        verbose=True,          # 터미널에 상세 수치 출력
        workers=4              # 데이터 로딩 속도 (M2 코어에 적합)
    )

if __name__ == "__main__":
    train_kickboard_model()