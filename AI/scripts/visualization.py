import pandas as pd
import matplotlib.pyplot as plt
import os

# ---------------------------------------------------------
# [설정] results.csv 파일 경로 (본인 경로에 맞게 수정)
# ---------------------------------------------------------
csv_path = 'Kickboard_AI/m2_safety_s_v1/results.csv' 
output_dir = 'Kickboard_AI/m2_safety_s_v1/graphs'

# 저장 폴더 생성
os.makedirs(output_dir, exist_ok=True)

def plot_training_results(file_path):
    if not os.path.exists(file_path):
        print(f"❌ 파일을 찾을 수 없습니다: {file_path}")
        return

    # 1. CSV 파일 읽기
    df = pd.read_csv(file_path)
    df.columns = [c.strip() for c in df.columns] # 컬럼명 공백 제거
    
    print("📋 데이터 로드 완료. 컬럼 개수:", len(df.columns))

    # 2. 그래프 스타일 설정
    plt.style.use('seaborn-v0_8-whitegrid')
    plt.rcParams['figure.figsize'] = (15, 10)
    plt.rcParams['font.family'] = 'sans-serif'

    # -----------------------------------------------------
    # (1) Loss 그래프 (학습 오차)
    # -----------------------------------------------------
    fig, axes = plt.subplots(2, 3, figsize=(18, 10))
    fig.suptitle('Training & Validation Losses', fontsize=16, fontweight='bold')

    # Train Loss
    if 'train/box_loss' in df.columns:
        axes[0, 0].plot(df['epoch'], df['train/box_loss'], label='Train Box', color='tab:blue')
        axes[0, 0].set_title('Box Loss (Train)')
        axes[0, 0].set_ylabel('Loss')
    
    if 'train/cls_loss' in df.columns:
        axes[0, 1].plot(df['epoch'], df['train/cls_loss'], label='Train Class', color='tab:orange')
        axes[0, 1].set_title('Class Loss (Train)')
    
    if 'train/dfl_loss' in df.columns:
        axes[0, 2].plot(df['epoch'], df['train/dfl_loss'], label='Train DFL', color='tab:green')
        axes[0, 2].set_title('DFL Loss (Train)')

    # Val Loss
    if 'val/box_loss' in df.columns:
        axes[1, 0].plot(df['epoch'], df['val/box_loss'], label='Val Box', color='tab:blue', linestyle='--')
        axes[1, 0].set_title('Box Loss (Validation)')
        axes[1, 0].set_xlabel('Epoch')
    
    if 'val/cls_loss' in df.columns:
        axes[1, 1].plot(df['epoch'], df['val/cls_loss'], label='Val Class', color='tab:orange', linestyle='--')
        axes[1, 1].set_title('Class Loss (Validation)')
        axes[1, 1].set_xlabel('Epoch')

    if 'val/dfl_loss' in df.columns:
        axes[1, 2].plot(df['epoch'], df['val/dfl_loss'], label='Val DFL', color='tab:green', linestyle='--')
        axes[1, 2].set_title('DFL Loss (Validation)')
        axes[1, 2].set_xlabel('Epoch')

    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig(os.path.join(output_dir, 'loss_metrics.png'), dpi=300)
    
    # -----------------------------------------------------
    # (2) Performance 그래프 (성능 지표) - 수정됨!
    # -----------------------------------------------------
    plt.figure(figsize=(12, 8))
    
    # mAP50 (빨간 실선)
    if 'metrics/mAP50(B)' in df.columns:
        plt.plot(df['epoch'], df['metrics/mAP50(B)'], label='mAP@50', color='#d62728', linewidth=2.5)
    
    # mAP50-95 (파란 실선)
    if 'metrics/mAP50-95(B)' in df.columns:
        plt.plot(df['epoch'], df['metrics/mAP50-95(B)'], label='mAP@50-95', color='#1f77b4', linewidth=2.5)
        
    # [수정] Precision & Recall을 실선으로 변경하고 두껍게 처리
    if 'metrics/precision(B)' in df.columns:
        plt.plot(df['epoch'], df['metrics/precision(B)'], label='Precision', color='#2ca02c', linewidth=2.0, linestyle='-') # 초록 실선
    
    if 'metrics/recall(B)' in df.columns:
        plt.plot(df['epoch'], df['metrics/recall(B)'], label='Recall', color='#ff7f0e', linewidth=2.0, linestyle='-') # 주황 실선

    plt.title('Model Performance Metrics (mAP, Precision, Recall)', fontsize=16, fontweight='bold')
    plt.xlabel('Epoch')
    plt.ylabel('Score (0.0 - 1.0)')
    plt.legend(fontsize=12, loc='lower right') # 범례 글자 키우고 위치 조정
    plt.grid(True, alpha=0.5)
    plt.ylim(0, 1.05) # y축 범위를 0~1로 고정하여 보기 편하게 함
    
    save_path = os.path.join(output_dir, 'performance_metrics.png')
    plt.savefig(save_path, dpi=300)
    print(f"✅ 그래프 저장 완료: {save_path}")
    plt.show()

if __name__ == "__main__":
    plot_training_results(csv_path)