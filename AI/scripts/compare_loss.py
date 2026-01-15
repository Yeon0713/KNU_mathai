import pandas as pd
import matplotlib.pyplot as plt
import os

# ---------------------------------------------------------
# [설정] results.csv 파일 경로
# ---------------------------------------------------------
csv_path = 'Kickboard_AI/m2_safety_s_v1/results.csv' 
output_dir = 'Kickboard_AI/m2_safety_s_v1/graphs'

# 저장 폴더 생성
os.makedirs(output_dir, exist_ok=True)

def plot_overlay_losses(file_path):
    if not os.path.exists(file_path):
        print(f"❌ 파일을 찾을 수 없습니다: {file_path}")
        return

    # 1. 데이터 로드 및 전처리
    df = pd.read_csv(file_path)
    df.columns = [c.strip() for c in df.columns] # 컬럼명 공백 제거

    # 2. 그래프 설정 (1행 3열 구조)
    fig, axes = plt.subplots(1, 3, figsize=(20, 6))
    fig.suptitle('Train vs Validation Loss Comparison', fontsize=20, fontweight='bold')

    # 스타일 설정
    train_color = '#1f77b4' # 파란색 (Train)
    val_color = '#d62728'   # 빨간색 (Val)
    
    # -----------------------------------------------------
    # (1) Box Loss (위치 정확도)
    # -----------------------------------------------------
    if 'train/box_loss' in df.columns and 'val/box_loss' in df.columns:
        ax = axes[0]
        ax.plot(df['epoch'], df['train/box_loss'], label='Train Box', color=train_color, linewidth=2)
        ax.plot(df['epoch'], df['val/box_loss'], label='Val Box', color=val_color, linestyle='--', linewidth=2)
        
        ax.set_title('Box Loss (Location)', fontsize=14)
        ax.set_xlabel('Epoch')
        ax.set_ylabel('Loss')
        ax.legend()
        ax.grid(True, alpha=0.3)

    # -----------------------------------------------------
    # (2) Class Loss (객체 분류 정확도)
    # -----------------------------------------------------
    if 'train/cls_loss' in df.columns and 'val/cls_loss' in df.columns:
        ax = axes[1]
        ax.plot(df['epoch'], df['train/cls_loss'], label='Train Cls', color=train_color, linewidth=2)
        ax.plot(df['epoch'], df['val/cls_loss'], label='Val Cls', color=val_color, linestyle='--', linewidth=2)
        
        ax.set_title('Class Loss (Classification)', fontsize=14)
        ax.set_xlabel('Epoch')
        ax.legend()
        ax.grid(True, alpha=0.3)

    # -----------------------------------------------------
    # (3) DFL Loss (바운딩 박스 정교함)
    # -----------------------------------------------------
    if 'train/dfl_loss' in df.columns and 'val/dfl_loss' in df.columns:
        ax = axes[2]
        ax.plot(df['epoch'], df['train/dfl_loss'], label='Train DFL', color=train_color, linewidth=2)
        ax.plot(df['epoch'], df['val/dfl_loss'], label='Val DFL', color=val_color, linestyle='--', linewidth=2)
        
        ax.set_title('DFL Loss (Refinement)', fontsize=14)
        ax.set_xlabel('Epoch')
        ax.legend()
        ax.grid(True, alpha=0.3)

    # 3. 저장 및 출력
    plt.tight_layout()
    save_path = os.path.join(output_dir, 'loss_comparison.png')
    plt.savefig(save_path, dpi=300)
    print(f"✅ 비교 그래프 저장 완료: {save_path}")
    plt.show()

if __name__ == "__main__":
    plot_overlay_losses(csv_path)