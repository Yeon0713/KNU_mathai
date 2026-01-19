from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.api import reports
from app.database import create_db_and_tables
from pathlib import Path

# FastAPI 애플리케이션 인스턴스 생성
app = FastAPI()


# [추가] 서버 상태 확인을 위한 루트 엔드포인트
@app.get("/")
async def health_check():
    """서버가 정상적으로 동작하는지 확인하는 간단한 엔드포인트입니다."""
    return {"status": "ok", "message": "Pothole detection server is running!"}

# 앱 시작 시 데이터베이스와 테이블 생성
@app.on_event("startup")
def on_startup():
    create_db_and_tables()

# static 디렉토리의 절대 경로를 계산합니다.
# 이 main.py 파일의 부모 디렉토리(app)의 부모 디렉토리(프로젝트 루트)에 있는 static 폴더를 가리킵니다.
STATIC_DIR = Path(__file__).resolve().parent.parent / "static"

# 정적 파일(이미지, CSS 등)을 제공하기 위한 설정
# directory 경로를 절대 경로로 지정하여 안정성을 높입니다.
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

# reports.py 파일에 정의된 API 라우터를 메인 앱에 포함시킵니다.
app.include_router(reports.router)
