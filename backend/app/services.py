import os
import uuid
import math
import aiofiles
from pathlib import Path
from fastapi import UploadFile
from ultralytics import YOLO

from . import crud, schemas

UPLOAD_DIRECTORY = Path("static/uploads")

# 모델 로드: models/india_spirit.pt 파일이 프로젝트 루트의 models 디렉토리에 있어야 합니다.
try:
    model = YOLO("app/models/india_spirit.pt")
except Exception as e:
    print(f"Warning: 모델을 로드할 수 없습니다. {e}")
    model = None

async def save_report_image(file: UploadFile) -> str:
    """업로드된 이미지 파일을 저장하고 웹 경로를 반환합니다."""
    # static/uploads 디렉토리가 없으면 생성
    UPLOAD_DIRECTORY.mkdir(parents=True, exist_ok=True)
    
    # 고유 파일명 생성
    extension = Path(file.filename).suffix if file.filename else ""
    image_filename = f"{uuid.uuid4()}{extension}"
    image_path_for_save = UPLOAD_DIRECTORY / image_filename
    
    # 비동기적으로 파일 저장
    async with aiofiles.open(image_path_for_save, "wb") as out_file:
        content = await file.read()
        await out_file.write(content)
        
    # 웹에서 접근할 수 있는 경로 반환
    return f"/{image_path_for_save.as_posix()}"

def verify_pothole(image_path: str) -> bool:
    """이미지를 분석하여 포트홀이 존재하는지 확인합니다."""
    if model is None:
        print("❌ 오류: AI 모델이 로드되지 않았습니다. models 폴더를 확인해주세요.")
        # 모델이 없으면 분석 불가하므로 False 반환 (혹은 정책에 따라 True)
        return False

    # 웹 경로를 파일 시스템 경로로 변환
    file_path = image_path.lstrip("/")
    
    # 예측 수행 (conf: 신뢰도 임계값. 0.25 -> 0.1로 낮춰서 민감하게 탐지하도록 변경)
    results = model.predict(file_path, conf=0.25, verbose=False)
    
    # 탐지된 객체가 있는지 확인
    for result in results:
        if len(result.boxes) > 0:
            print(f"✅ 포트홀 탐지됨! (발견된 객체 수: {len(result.boxes)})")
            for box in result.boxes:
                print(f"   - 신뢰도: {box.conf.item():.4f}")
            return True
    
    print(f"⚠️ 포트홀 미탐지 (이미지: {file_path}) - 신뢰도 0.1 미만")
    return False

def delete_image_file(image_path: str):
    """지정된 경로의 이미지 파일을 삭제합니다."""
    if image_path:
        file_path = Path(image_path.lstrip('/'))
        file_path.unlink(missing_ok=True)

def calculate_distance(lat1, lon1, lat2, lon2):
    """두 좌표(위도, 경도) 사이의 거리를 미터(m) 단위로 계산합니다 (Haversine formula)."""
    R = 6371000  # 지구 반지름 (미터)
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c

def create_new_report(report: schemas.ReportCreate, image_path: str, status: schemas.ReportStatus = None):
    """새로운 신고를 생성하는 비즈니스 로직."""
    
    # 1. 기존 신고 내역 조회 (반려된 건 제외)
    # 주의: 데이터가 많아지면 DB단에서 거리 계산을 하거나(PostGIS), 쿼리를 최적화해야 합니다.
    existing_reports = crud.get_reports(exclude_rejected=True)
    
    # 2. 반경 10m 내에 중복된 신고가 있는지 확인 (테스트를 위해 범위를 좁게 설정)
    group_id = None
    DUPLICATE_RADIUS_METER = 20.0

    for r in existing_reports:
        dist = calculate_distance(report.latitude, report.longitude, r.latitude, r.longitude)
        if dist <= DUPLICATE_RADIUS_METER:
            # 근처에 이미 신고된 건이 있다면, 그 건의 그룹 ID를 가져옴
            # (기존 건에 그룹 ID가 없다면, 이번 건은 새로운 그룹의 시작으로 간주하거나 추후 마이그레이션 필요)
            if hasattr(r, 'pothole_group_id') and r.pothole_group_id:
                group_id = r.pothole_group_id
                break
    
    # 3. 중복된 건이 없거나 그룹 ID를 찾지 못했으면 새로운 그룹 ID 생성
    if not group_id:
        group_id = str(uuid.uuid4())
    
    report.pothole_group_id = group_id
    
    return crud.create_report(report=report, image_path=image_path, status=status)

def remove_report(report_id: int):
    """
    신고를 삭제하는 비즈니스 로직.
    1. DB에서 리포트 정보를 가져옵니다.
    2. 이미지 파일을 삭제합니다.
    3. DB에서 리포트 레코드를 삭제합니다.
    """
    report = crud.get_report(report_id=report_id)
    if report:
        # 웹 경로를 파일 시스템 경로로 변환
        delete_image_file(report.image_path)
        
        # DB 레코드 삭제
        return crud.delete_report(report_id=report_id)
    return None # 삭제할 리포트가 없는 경우

def remove_pothole_group(group_id: str):
    """
    특정 그룹에 속한 모든 신고 내역과 이미지를 삭제합니다.
    """
    reports = crud.get_reports_by_group(group_id)
    for row in reports:
        remove_report(row.id)

def get_pothole_groups():
    """
    모든 신고 내역을 조회하여 그룹 ID별로 묶어서 반환합니다.
    지도에 핀을 하나만 찍기 위해 그룹의 평균 좌표를 계산합니다.
    """
    reports = crud.get_reports(exclude_rejected=True)
    groups = {}
    
    for r in reports:
        # 그룹 ID가 없는 경우(구 데이터 등)는 개별 그룹으로 취급하거나 무시
        gid = r.pothole_group_id
        if not gid:
            gid = f"ungrouped_{r.id}"
            
        if gid not in groups:
            groups[gid] = {
                "group_id": gid,
                "lat_sum": 0.0,
                "lon_sum": 0.0,
                "count": 0,
                "report_ids": [],
                "latest_at": r.reported_at,
                "statuses": set() # 그룹 내 상태들을 모으기 위한 집합
            }
            
        g = groups[gid]
        g["lat_sum"] += r.latitude
        g["lon_sum"] += r.longitude
        g["count"] += 1
        g["report_ids"].append(r.id)
        g["statuses"].add(r.status) # 상태 수집
        if r.reported_at > g["latest_at"]:
            g["latest_at"] = r.reported_at
            
    # 결과 리스트 변환 (평균 좌표 계산)
    result = []
    for gid, g in groups.items():
        # 그룹의 대표 상태 결정 로직
        # 우선순위: 접수됨(위험/미처리) > 처리중 > 완료 > 포트홀아님
        statuses = g["statuses"]
        if "접수됨" in statuses:
            final_status = "접수됨"
        elif "처리중" in statuses:
            final_status = "처리중"
        elif "완료" in statuses:
            final_status = "완료"
        else:
            final_status = "포트홀아님"

        result.append({
            "group_id": gid,
            "latitude": g["lat_sum"] / g["count"],
            "longitude": g["lon_sum"] / g["count"],
            "report_ids": g["report_ids"],
            "report_count": g["count"],
            "latest_reported_at": g["latest_at"],
            "status": final_status
        })
        
    return result
