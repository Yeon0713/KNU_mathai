# 🛴 Safety Scooter (전동 킥보드 안전 주행 보조 시스템)

**Safety Scooter**는 전동 킥보드 이용자의 안전을 위해 개발된 AI 기반 모바일 애플리케이션입니다.
스마트폰을 킥보드에 거치하여 주행 중 전방의 위험 요소(사람, 차량, 포트홀 등)를 실시간으로 감지하고, 헬멧 착용 여부를 검사하여 안전한 주행 문화를 유도합니다.

---

## 📋 목차

1. [프로젝트 개요](#-프로젝트-개요)
2. [주요 기능](#-주요-기능)
3. [시작하기 (설치 및 실행)](#-시작하기-설치-및-실행)
4. [프로젝트 구조](#-프로젝트-구조)
5. [핵심 로직 설명](#-핵심-로직-설명)
6. [트러블슈팅](#-트러블슈팅)

---

## 🌟 프로젝트 개요

이 프로젝트는 Flutter 프레임워크와 On-device AI 기술(TFLite)을 활용하여 네트워크 연결 없이도 실시간으로 위험을 감지할 수 있도록 설계되었습니다.

*   **Target Device**: Android (iOS는 권한 설정 추가 필요)
*   **Minimum SDK**: Android API 21+ (Camera2 API 지원 필요)
*   **Key Tech**: Flutter, GetX, TensorFlow Lite (YOLOv11, Classification), Sensor Fusion

---

## 🚀 주요 기능

### 1. 헬멧 착용 감지 (Helmet Check)
*   앱 실행 시 전면 카메라를 통해 사용자의 헬멧 착용 여부를 검사합니다.
*   AI 모델이 헬멧 착용을 감지하고 5초간 상태가 유지되면 주행 화면으로 넘어갑니다.
*   **관련 파일**: `lib/screens/helmet_check_screen.dart`, `lib/services/helmet_service.dart`

### 2. 주행 보조 및 위험 감지 (Ride Assistance)
*   후면 카메라를 통해 전방 도로 상황을 실시간으로 분석합니다.
*   **객체 탐지**: 사람, 차량, 트럭 등을 인식합니다.
*   **위험 감지**: `DANGER_HIT`(포트홀 등) 클래스나 충돌 위험이 있는 객체가 감지되면 화면에 붉은 테두리와 경고음으로 알립니다.
*   **관련 파일**: `lib/screens/home_screen.dart`, `lib/services/ai_handler.dart`

### 3. 주행 대시보드 (Dashboard)
*   현재 속도(GPS 기반), 배터리 잔량, 주행 시간 등을 표시합니다.
*   디버그 모드를 통해 FPS, 감지된 객체 수, 센서 데이터 등을 실시간으로 확인할 수 있습니다.

### 4. 자동 리포트 (Auto Report)
*   위험 상황 발생 시 당시의 위치(위도, 경도)와 현장 사진을 서버로 자동 전송합니다.
*   **관련 파일**: `lib/services/api_service.dart`

---

## 💻 시작하기 (설치 및 실행)

해당 Flutter를 실행하기 위해서 아래 절차를 따라 환경을 설정하세요.

### 1. 필수 요구 사항 (Prerequisites)
*   Flutter SDK (3.x 이상 권장)
*   Android Studio 또는 VS Code (Flutter/Dart 플러그인 설치)
*   Android 기기 (에뮬레이터는 카메라/센서 테스트가 제한적임)

### 2. 프로젝트 클론 및 의존성 설치
```bash
git clone https://github.com/KNU-mathai/safety_scooter.git
cd safety_scooter
flutter pub get
```

### 3. Assets 설정 (중요!)
이 프로젝트는 AI 모델 파일을 사용합니다. `assets/models/` 폴더에 다음 파일들이 존재하는지 확인하세요.
*   `helmet_model.tflite` (헬멧 분류 모델)
*   `model.tflite` (YOLO 객체 탐지 모델)
*   `labels.txt` (YOLO 클래스 라벨)
*   `AssetManifest.json` (자동 생성되지만, 로드 실패 시 `flutter clean` 후 다시 빌드)

### 4. 서버 주소 설정
`lib/services/api_service.dart` 파일에서 백엔드 서버 주소를 본인의 환경에 맞게 수정해야 합니다.
```dart
// lib/services/api_service.dart
final String _serverUrl = 'http://YOUR_SERVER_IP:8000/api/report';
```

### 5. 앱 실행
실제 Android 기기를 USB로 연결하고 디버깅 모드를 켠 후 실행하세요.
```bash
flutter run
```
*   **권한 허용**: 앱 최초 실행 시 **위치** 권한과 **카메라** 권한을 차례로 허용해야 합니다.

---

## 📂 프로젝트 구조

코드는 `lib/` 폴더 내에 기능별로 구조화되어 있습니다.

```text
lib/
├── main.dart                  # 앱 진입점 (초기화, 테마, 라우팅)
├── controllers/               # [GetX] 상태 관리 및 비즈니스 로직
│   ├── global_controller.dart   # 앱 전역 상태 (카메라 제어, AI 로직 통합)
│   ├── ride_controller.dart     # 주행 타이머 및 상태 관리
│   └── settings_controller.dart # 설정 값 관리 (GetStorage)
├── services/                  # [Service] 외부 시스템 통신 및 백그라운드 작업
│   ├── ai_handler.dart          # YOLO 객체 탐지 로직 (flutter_vision)
│   ├── helmet_service.dart      # 헬멧 분류 로직 (tflite_flutter)
│   ├── sensor_service.dart      # GPS 및 가속도 센서 핸들링
│   └── api_service.dart         # 백엔드 API 통신
├── screens/                   # [UI] 화면 구성
│   ├── helmet_check_screen.dart # 헬멧 인증 화면
│   ├── home_screen.dart         # 메인 주행 대시보드
│   ├── camera_view.dart         # 카메라 프리뷰 위젯
│   ├── settings_screen.dart     # 설정 화면
│   └── ride_summary_screen.dart # 주행 종료 후 요약 화면
├── widgets/                   # [UI] 재사용 가능한 위젯 및 오버레이
│   ├── bounding_box_overlay.dart # AI 탐지 박스 그리기
│   ├── dashboard_overlay.dart    # 속도계, 버튼 등 HUD
│   └── danger_border.dart        # 위험 감지 시 붉은 테두리 효과
└── utils/                     # 유틸리티
    ├── notification_helper.dart  # 경고음 재생 헬퍼
    └── languages.dart            # 다국어 지원 문자열
```

---

## 🧠 핵심 로직 설명

### 1. 헬멧 인증 프로세스 (`HelmetCheckScreen`)
1.  앱 시작 시 `GlobalController`가 `startHelmetCheckMode()`를 호출하여 **전면 카메라**를 켭니다.
2.  `HelmetService`가 카메라 프레임을 받아 헬멧 착용 여부를 추론합니다.
3.  헬멧이 감지되면 `GlobalController` 내부의 타이머가 작동하여 5초간 유지를 확인합니다.
4.  인증이 완료되면 `HomeScreen`으로 이동합니다.

### 2. 주행 및 위험 감지 (`HomeScreen`)
1.  화면 진입 시 `startRideMode()`가 호출되어 **후면 카메라**로 전환됩니다.
2.  사용자가 **[주행 시작]** 버튼을 누르면 `RideController`가 타이머를 시작하고 AI 추론을 활성화합니다.
3.  **AI 루프 (`GlobalController.processCameraImage`)**:
    *   카메라 이미지 -> `AiHandler` (YOLO 추론) -> 결과 리스트 반환.
    *   결과 중 `DANGER_HIT` 태그가 있거나, 특정 조건(속도 위반 등) 충족 시 `isDanger` 상태를 `true`로 변경.
4.  **위험 발생 시**:
    *   화면 테두리가 붉게 점멸 (`DangerBorder`).
    *   경고음 재생 (`NotificationHelper`).
    *   자동 리포트 설정이 켜져 있다면 서버로 데이터 전송.

### 3. 센서 융합 (`SensorService`)
*   **GPS**: 이동 속도를 계산하여 `displaySpeed`를 업데이트합니다.
*   **가속도계**: GPS 신호가 약한 곳(터널 등)에서도 진동을 감지하여 `isMoving` 상태를 보정합니다.

---

## 🔧 트러블슈팅

### Q. 앱 실행 직후 멈추거나 검은 화면이 나옵니다.
*   **권한 문제**: 앱 정보에서 카메라/위치 권한이 허용되어 있는지 확인하세요.
*   **모델 파일**: `assets/models/` 경로에 `.tflite` 파일이 없으면 초기화 중 에러가 발생합니다. 로그창(`Run` 탭)을 확인하세요.

### Q. "Unable to load asset" 에러가 발생합니다.
*   `pubspec.yaml` 파일의 `assets` 섹션에 모델 파일 경로가 정확히 명시되어 있는지 확인하고, `flutter clean` 후 다시 빌드하세요.

### Q. 위치 정보를 못 받아옵니다 (0.0 km/h).
*   실내에서는 GPS 수신이 어렵습니다. 야외에서 테스트하거나, 개발자 옵션의 '모의 위치 앱' 기능을 끄세요.
*   에뮬레이터 사용 시 Extended Controls에서 Location을 수동으로 설정해줘야 합니다.

### Q. 디버그 모드는 어떻게 켜나요?
*   메인 화면 하단의 **벌레 모양 아이콘(🐛)**을 누르면 디버그 패널이 열립니다. 여기서 FPS, 센서 값, 서버 응답 상태를 확인할 수 있습니다.

---

## 🤝 기여 가이드 (Contribution)

*   **Code Style**: Dart 공식 스타일 가이드를 따릅니다.
*   **State Management**: 비즈니스 로직은 반드시 `Controller`에 작성하고, UI는 `Obx`를 통해 반응형으로 구성하세요.
*   **Commit Message**: 기능 추가는 `feat:`, 버그 수정은 `fix:`, 리팩토링은 `refactor:` 접두사를 사용하세요.