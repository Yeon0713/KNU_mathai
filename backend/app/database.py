import sqlalchemy
from datetime import datetime

# SQLite 데이터베이스 파일 경로
DATABASE_URL = "sqlite:///./pothole.db"

# SQLAlchemy 데이터베이스 엔진 생성
# connect_args={"check_same_thread": False}는 SQLite 사용 시 FastAPI와 같은 다중 스레드 환경에서 필요합니다.
engine = sqlalchemy.create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False}
)

# 데이터베이스 테이블을 정의하기 위한 메타데이터 객체
metadata = sqlalchemy.MetaData()

# Pothole 테이블 정의
potholes = sqlalchemy.Table(
    "potholes",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True, index=True),
    sqlalchemy.Column("latitude", sqlalchemy.Float, nullable=False),
    sqlalchemy.Column("longitude", sqlalchemy.Float, nullable=False),
    sqlalchemy.Column("reported_at", sqlalchemy.DateTime, default=datetime.utcnow),
    sqlalchemy.Column("image_path", sqlalchemy.String, nullable=True),
    sqlalchemy.Column("status", sqlalchemy.String, default="접수됨", nullable=False),
    sqlalchemy.Column("pothole_group_id", sqlalchemy.String, nullable=True),
)

# 데이터베이스 생성 함수
def create_db_and_tables():
    metadata.create_all(bind=engine)
