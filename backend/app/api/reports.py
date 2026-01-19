import json
from fastapi import APIRouter, Request, Depends, UploadFile, File, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates

from app import crud, schemas, services

router = APIRouter()

# HTML 템플릿을 로드하기 위한 설정
templates = Jinja2Templates(directory="templates")


@router.get("/map", response_class=HTMLResponse)
async def map_view(request: Request):
    """지도 기반 대시보드 페이지를 보여줍니다."""
    return templates.TemplateResponse("map.html", {"request": request})


@router.get("/stats", response_class=HTMLResponse)
async def stats_view(request: Request):
    """통계 페이지: 신고 현황 통계를 보여줍니다."""
    reports = crud.get_reports()
    
    # 클라이언트(Chart.js)에서 사용할 수 있도록 데이터를 JSON 직렬화 가능한 형태로 변환
    reports_data = []
    for row in reports:
        r = dict(row._mapping)
        reports_data.append({
            "status": r["status"],
            "latitude": r["latitude"],
            "longitude": r["longitude"],
            "reported_at": r["reported_at"].isoformat()
        })
        
    return templates.TemplateResponse(
        "stats.html",
        {"request": request, "reports_data": json.dumps(reports_data)}
    )


@router.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request):
    """대시보드 페이지: 모든 신고 내역을 그룹별로 묶어서 보여줍니다."""
    # 포트홀이 아닌 것(REJECTED)은 제외하고 가져옵니다.
    reports = crud.get_reports(exclude_rejected=True)
    
    # 그룹핑 로직
    groups = {}
    for row in reports:
        r = dict(row._mapping)
        gid = r.get("pothole_group_id")
        
        if not gid:
            gid = "미분류 (그룹 ID 없음)"
            
        if gid not in groups:
            groups[gid] = {
                "group_id": gid,
                "reports": [],
                "count": 0,
                "latest_at": r["reported_at"]
            }
            
        groups[gid]["reports"].append(r)
        groups[gid]["count"] += 1
        if r["reported_at"] > groups[gid]["latest_at"]:
            groups[gid]["latest_at"] = r["reported_at"]
            
    # 최신순 정렬
    group_list = sorted(groups.values(), key=lambda x: x["latest_at"], reverse=True)

    return templates.TemplateResponse(
        "index.html", 
        {"request": request, "groups": group_list}
    )


@router.get("/debug", response_class=HTMLResponse)
async def debug_view(request: Request):
    """디버깅 페이지: 포트홀인 것과 아닌 것을 구분하여 보여줍니다."""
    reports = crud.get_reports()
    all_reports = [dict(row._mapping) for row in reports]
    
    # 상태에 따라 분류
    detected_reports = [r for r in all_reports if r.get('status') != schemas.ReportStatus.REJECTED.value]
    rejected_reports = [r for r in all_reports if r.get('status') == schemas.ReportStatus.REJECTED.value]
    
    return templates.TemplateResponse(
        "debug.html",
        {"request": request, "detected_reports": detected_reports, "rejected_reports": rejected_reports}
    )


@router.post("/api/report")
async def create_pothole_report(
    latitude: float = Form(...),
    longitude: float = Form(...),
    file: UploadFile = File(...)
):
    """API: 새로운 포트홀 신고를 생성합니다."""
    # 1. 이미지 파일 저장
    image_path = await services.save_report_image(file)
    
    # 2. 모델을 사용하여 포트홀 여부 확인 (거부하지 않고 결과만 저장)
    is_pothole = services.verify_pothole(image_path)
    
    # 포트홀 여부에 따라 상태 결정
    report_status = schemas.ReportStatus.REPORTED if is_pothole else schemas.ReportStatus.REJECTED

    # 3. 데이터베이스에 저장할 데이터 준비
    report_data = schemas.ReportCreate(latitude=latitude, longitude=longitude)
    
    # 4. 서비스 로직을 통해 신고 생성
    services.create_new_report(report=report_data, image_path=image_path, status=report_status)

    return {"status": "success", "filename": file.filename, "pothole_detected": is_pothole}


@router.post("/report/delete/{report_id}")
async def delete_report_endpoint(report_id: int):
    """지정된 ID의 신고 내역을 삭제합니다."""
    services.remove_report(report_id)
    return RedirectResponse(url="/dashboard", status_code=303)


@router.get("/api/reports", response_model=list[schemas.Report])
async def get_all_reports_as_json():
    """모든 신고 내역을 JSON으로 반환합니다."""
    reports = crud.get_reports(exclude_rejected=True)
    # SQLAlchemy의 RowProxy 객체를 Pydantic 모델 인스턴스로 변환
    # schemas.Report의 Config.from_attributes = True 설정 덕분에 가능합니다.
    return [schemas.Report.from_orm(report) for report in reports]


@router.post("/report/update_status/{report_id}")
async def update_report_status_endpoint(report_id: int, status: schemas.ReportStatus = Form(...)):
    """지정된 ID의 신고 내역의 상태를 변경합니다."""
    crud.update_report_status(report_id=report_id, status=status)
    return RedirectResponse(url="/dashboard", status_code=303)

@router.post("/api/group/update_status/{group_id}")
async def update_group_status_endpoint(group_id: str, status: schemas.ReportStatus = Form(...)):
    """지정된 그룹 ID의 모든 신고 내역 상태를 변경합니다."""
    crud.update_group_status(pothole_group_id=group_id, status=status)
    return RedirectResponse(url="/dashboard", status_code=303)

@router.post("/api/group/delete/{group_id}")
async def delete_group_endpoint(group_id: str):
    """지정된 그룹 ID의 모든 신고 내역을 삭제합니다."""
    services.remove_pothole_group(group_id)
    return RedirectResponse(url="/dashboard", status_code=303)

@router.get("/api/pothole-groups", response_model=list[schemas.PotholeGroup])
async def get_pothole_groups_json():
    """포트홀 그룹별로 묶인 데이터를 반환합니다 (지도 표시용)."""
    # services.py에 새로 만든 집계 함수 호출
    return services.get_pothole_groups()
