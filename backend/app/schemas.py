from pydantic import BaseModel
from datetime import datetime
from enum import Enum

# 신고 처리 상태를 정의하는 Enum
class ReportStatus(str, Enum):
    REPORTED = "접수됨"
    IN_PROGRESS = "처리중"
    COMPLETED = "완료"
    REJECTED = "포트홀아님"

# 데이터베이스에서 읽어온 데이터의 기본 스키마
class ReportBase(BaseModel):
    latitude: float
    longitude: float

# 리포트 생성을 위한 스키마 (API 입력)
class ReportCreate(ReportBase):
    pothole_group_id: str | None = None

# 리포트 정보를 반환하기 위한 스키마 (API 출력)
class Report(ReportBase):
    id: int
    reported_at: datetime
    image_path: str | None
    status: ReportStatus # 상태 필드 추가
    pothole_group_id: str | None

    class Config:
        from_attributes = True # SQLAlchemy 모델과 같은 ORM 모델로부터 데이터를 읽어올 수 있게 함

# 지도 표시를 위한 포트홀 그룹 스키마
class PotholeGroup(BaseModel):
    group_id: str
    latitude: float  # 그룹의 평균 위도
    longitude: float # 그룹의 평균 경도
    report_ids: list[int] # 포함된 신고 ID 목록
    report_count: int     # 포함된 신고 개수
    latest_reported_at: datetime # 가장 최근 신고 시각
    status: str # 그룹의 대표 상태 (접수됨, 처리중, 완료 등)
