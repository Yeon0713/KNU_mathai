import sqlalchemy
from . import schemas
from .database import potholes, engine

def get_reports(skip: int = 0, limit: int = 100, exclude_rejected: bool = False):
    """모든 신고 내역을 최신순으로 조회합니다."""
    query = potholes.select()
    
    if exclude_rejected:
        query = query.where(potholes.c.status != schemas.ReportStatus.REJECTED.value)
        
    query = query.order_by(potholes.c.reported_at.desc()).offset(skip).limit(limit)
    with engine.connect() as connection:
        results = connection.execute(query).fetchall()
    return results

def get_report(report_id: int):
    """ID로 특정 신고 내역을 조회합니다."""
    query = potholes.select().where(potholes.c.id == report_id)
    with engine.connect() as connection:
        result = connection.execute(query).fetchone()
    return result

def create_report(report: schemas.ReportCreate, image_path: str, status: schemas.ReportStatus = None):
    """새로운 신고 내역을 데이터베이스에 생성합니다."""
    values = {
        "latitude": report.latitude,
        "longitude": report.longitude,
        "image_path": image_path,
        "pothole_group_id": report.pothole_group_id  # [수정] 그룹 ID 저장 추가
    }
    if status:
        values["status"] = status.value

    query = potholes.insert().values(**values)
    with engine.connect() as connection:
        result = connection.execute(query)
        connection.commit()
        # 삽입된 레코드의 ID를 가져오기 위해 lastrowid를 사용 (필요 시)
        # 여기서는 생성된 객체를 다시 조회하여 반환하는 것이 더 일반적입니다.
        # last_id = result.lastrowid
        # return get_report(last_id)
    return {"status": "success"} # 간단하게 상태만 반환

def delete_report(report_id: int):
    """ID로 특정 신고 내역을 데이터베이스에서 삭제합니다."""
    query = potholes.delete().where(potholes.c.id == report_id)
    with engine.connect() as connection:
        connection.execute(query)
        connection.commit()
    return {"status": "success"}

def update_report_status(report_id: int, status: schemas.ReportStatus):
    """특정 신고 내역의 상태를 변경합니다."""
    query = (
        sqlalchemy.update(potholes)
        .where(potholes.c.id == report_id)
        .values(status=status.value)
    )
    with engine.connect() as connection:
        connection.execute(query)
        connection.commit()
    return get_report(report_id=report_id)

def update_group_status(pothole_group_id: str, status: schemas.ReportStatus):
    """특정 그룹 ID를 가진 모든 신고 내역의 상태를 변경합니다."""
    # '미분류' 그룹인 경우 pothole_group_id가 NULL인 항목들을 업데이트
    target_id = pothole_group_id
    if pothole_group_id == "미분류 (그룹 ID 없음)":
        target_id = None
        
    query = (
        sqlalchemy.update(potholes)
        .where(potholes.c.pothole_group_id == target_id)
        .values(status=status.value)
    )
    with engine.connect() as connection:
        connection.execute(query)
        connection.commit()
    return {"status": "success"}

def get_reports_by_group(pothole_group_id: str):
    """특정 그룹 ID에 속한 모든 신고 내역을 조회합니다."""
    target_id = pothole_group_id
    if pothole_group_id == "미분류 (그룹 ID 없음)":
        target_id = None
        
    query = potholes.select().where(potholes.c.pothole_group_id == target_id)
    with engine.connect() as connection:
        results = connection.execute(query).fetchall()
    return results
