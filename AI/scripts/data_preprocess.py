import os
import json
import shutil
import random
from tqdm import tqdm

# 경로 설정
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_ROOT = os.path.join(BASE_DIR, '../data')
OUTPUT_DIR = os.path.join(DATA_ROOT, 'yolo_dataset')

DATA_SETS = [
    {'img': 'A01_image', 'lbl': 'A01_label'},
    {'img': 'I01_image', 'lbl': 'I01_label'}
]

def build_yolo_dataset():
    # 1. 저장 폴더 생성 (train과 val 폴더를 각각 생성)
    for split in ['train', 'val']:
        os.makedirs(os.path.join(OUTPUT_DIR, f'images/{split}'), exist_ok=True)
        os.makedirs(os.path.join(OUTPUT_DIR, f'labels/{split}'), exist_ok=True)

    print("--- 킥보드 위험 탐지 특화 전처리 및 데이터 분리 시작 ---")
    
    for dataset in DATA_SETS:
        img_dir = os.path.join(DATA_ROOT, dataset['img'])
        lbl_dir = os.path.join(DATA_ROOT, dataset['lbl'])
        if not os.path.exists(lbl_dir): continue
        
        json_files = [f for f in os.listdir(lbl_dir) if f.endswith('.json')]
        
        for j_file in tqdm(json_files, desc=f"Processing {dataset['lbl']}"):
            with open(os.path.join(lbl_dir, j_file), 'r') as f:
                data = json.load(f)
            
            img_name = data['images']['file_name']
            src_img_path = os.path.join(img_dir, img_name)
            
            if os.path.exists(src_img_path):
                # 80%는 train, 20%는 val로 배정
                split = 'train' if random.random() < 0.8 else 'val'
                
                img_w, img_h = data['images']['width'], data['images']['height']
                valid_annotations = []

                for ann in data['annotations']:
                    raw_id = ann['category_id']
                    bbox = ann['bbox']
                    
                    # 거리 필터링 (상단 무시)
                    y_center = bbox[1] + (bbox[3] / 2)
                    if y_center < (img_h * 0.4): continue

                    # 클래스 재그룹화 (0: Danger, 1: Caution)
                    if raw_id in [8, 10, 1, 2]: new_id = 0
                    elif raw_id in [3, 4, 5, 6, 7]: new_id = 1
                    else: continue
                    
                    xc = (bbox[0] + bbox[2]/2) / img_w
                    yc = (bbox[1] + bbox[3]/2) / img_h
                    w = bbox[2] / img_w
                    h = bbox[3] / img_h
                    valid_annotations.append(f"{new_id} {xc:.6f} {yc:.6f} {w:.6f} {h:.6f}")

                if valid_annotations:
                    # 데이터 균형: 포트홀 없으면 30%만 포함
                    has_real_danger = any(ann.get('category_id') in [8, 10] for ann in data['annotations'])
                    if not has_real_danger and random.random() > 0.3:
                        continue

                    # 이미지 및 라벨 복사/저장 (결정된 split 폴더로)
                    shutil.copy(src_img_path, os.path.join(OUTPUT_DIR, f'images/{split}', img_name))
                    txt_name = os.path.splitext(img_name)[0] + '.txt'
                    with open(os.path.join(OUTPUT_DIR, f'labels/{split}', txt_name), 'w') as tf:
                        tf.write("\n".join(valid_annotations))

    print(f"\n완료! Train/Val 분리 완료.")

if __name__ == "__main__":
    build_yolo_dataset()