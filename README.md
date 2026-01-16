# Safety Scooter - AI 기반 전동 킥보드 안전 주행 보조 시스템

## 1. 프로젝트 개요

**Safety Scooter**는 전동 킥보드 사용자의 안전을 증진시키기 위해 개발된 Flutter 기반의 모바일 애플리케이션입니다. 스마트폰의 카메라와 센서를 활용하여 주행 중 발생할 수 있는 잠재적 위험 요소를 실시간으로 감지하고 사용자에게 경고함으로써 사고를 예방하는 것을 목표로 합니다.

본 프로젝트는 AI 객체 감지 기술을 통해 전방의 장애물, 사람, 차량 등을 인식하고, 내장 센서 데이터(가속도, 자이로스코프)를 분석하여 급정거, 넘어짐과 같은 위험 상황을 감지합니다.

## 2. 주요 기능

- **🤖 실시간 AI 객체 감지 (Real-time AI Object Detection)**
  - 스마트폰 카메라를 통해 들어오는 영상에서 실시간으로 객체를 탐지합니다. (`flutter_vision`, `tflite_flutter`)
  - 사전 훈련된 YOLO 모델을 사용하여 사람, 자동차, 자전거 등 다양한 객체를 식별하고 화면에 경계 상자(Bounding Box)를 표시합니다.

- **📈 센서 데이터 모니터링 (Sensor Data Monitoring)**
  - 가속도계와 자이로스코프 센서를 사용하여 주행 상태(가속, 감속, 회전)를 실시간으로 모니터링합니다. (`sensors_plus`)
  - 급격한 움직임이나 충격을 감지하여 넘어짐과 같은 위험 상황을 판단합니다.

- **📍 위치 정보 (Geolocation)**
  - GPS를 통해 현재 위치 및 이동 속도 데이터를 수집합니다. (`geolocator`)
  - (향후 확장) 주행 경로 기록, 특정 구간 위험 알림 등의 기능에 활용될 수 있습니다.

- **⚠️ 위험 경고 및 알림 (Hazard Warning & Notification)**
  - 위험 객체 감지 또는 넘어짐과 같은 이벤트 발생 시 사용자에게 소리, 진동 등 즉각적인 알림을 제공합니다. (`audioplayers`)
  - 사용자가 위험을 빠르게 인지하고 대응할 수 있도록 돕습니다.

- **⚙️ 사용자 설정 (User Settings)**
  - 언어 변경(한국어/영어), 알림 활성화 등 앱의 주요 기능을 사용자가 직접 제어할 수 있는 설정 화면을 제공합니다.

## 3. 시스템 아키텍처

본 프로젝트는 GetX 라이브러리를 중심으로 상태 관리, 라우팅, 의존성 주입을 처리하며, 다음과 같은 구조로 설계되었습니다.

- **`lib/`**
  - **`main.dart`**: 앱의 시작점. GetX 컨트롤러 초기화 및 기본 라우팅을 설정합니다.
  - **`controllers/`**: 앱의 전역 상태와 비즈니스 로직을 관리합니다.
    - `global_controller.dart`: 앱의 전반적인 상태(AI 모델 로딩, 권한 상태 등)를 관리합니다.
    - `settings_controller.dart`: 사용자의 설정 값을 관리하고 저장합니다.
  - **`screens/`**: 사용자에게 보여지는 UI 화면들로 구성됩니다.
    - `home_screen.dart`: 메인 화면. 카메라 미리보기, 감지된 객체 정보, 센서 데이터를 표시합니다.
    - `camera_view.dart`: 카메라 화면과 AI 객체 감지 결과를 오버레이하여 보여주는 핵심 UI입니다.
    - `settings_screen.dart`: 앱 설정을 위한 UI 화면입니다.
  - **`services/`**: 백그라운드 작업 및 외부 서비스와의 통신을 담당합니다.
    - `ai_handler.dart`: `flutter_vision`을 사용하여 AI 모델을 로드하고, 카메라 이미지 프레임을 처리하여 객체 감지를 수행하는 서비스입니다.
    - `sensor_service.dart`: `sensors_plus`를 통해 디바이스 센서 데이터를 수신하고 관리합니다.
  - **`utils/`**: 공통으로 사용되는 유틸리티 함수들을 포함합니다.
    - `languages.dart`: 다국어 지원을 위한 텍스트 리소스를 정의합니다.
    - `notification_helper.dart`: 위험 상황 발생 시 알림(소리)을 재생하는 로직을 담당합니다.
  - **`widgets/`**: 여러 화면에서 재사용되는 UI 위젯을 정의합니다.
    - `bounding_box_painter.dart`: AI 모델이 감지한 객체 주위에 사각형(경계 상자)을 그리는 Custom Painter 입니다.

## 4. 핵심 기술 및 라이브러리

- **Framework**: `Flutter`
- **State Management**: `get` (GetX)
- **AI / Machine Learning**:
  - `flutter_vision`: TFLite 모델을 Flutter 앱에서 쉽게 사용할 수 있도록 돕는 고수준 라이브러리
  - `tflite_flutter`: TensorFlow Lite 모델을 직접 다루기 위한 저수준 API
- **Hardware & OS Access**:
  - `camera`: 디바이스 카메라 제어
  - `sensors_plus`: 가속도계, 자이로스코프 등 센서 접근
  - `geolocator`: GPS 위치 정보 접근
  - `permission_handler`: 카메라, 위치 등 민감한 권한 요청 및 관리
  - `audioplayers`: 경고음 등 오디오 파일 재생
- **Utilities**:
  - `package_info_plus`: 앱 버전 등 패키지 정보 조회

## 5. 실행 방법

1. **Flutter 개발 환경 설정**
   - Flutter 공식 홈페이지를 참고하여 Flutter SDK를 설치합니다.

2. **프로젝트 클론**
   ```bash
   git clone https://github.com/your-repository/KNU_mathai.git
   cd KNU_mathai/safety_scooter
   ```

3. **의존성 라이브러리 설치**
   ```bash
   flutter pub get
   ```

4. **앱 실행**
   - 연결된 디바이스 또는 에뮬레이터에서 아래 명령어로 앱을 실행합니다.
   ```bash
   flutter run
   ```
   > **참고**: 실제 디바이스에서 실행해야 카메라, GPS, 센서 기능을 정상적으로 테스트할 수 있습니다.

## 6. 향후 개선 과제

- **AI 모델 고도화**: 더 가볍고 정확한 최신 객체 감지 모델(e.g., YOLOv8, EfficientDet) 적용
- **데이터 로깅 및 분석**: 주행 중 감지된 위험 데이터, 센서 값 등을 서버에 기록하여 패턴 분석
- **클라우드 연동**: 사용자별 설정, 주행 기록 등을 클라우드에 동기화
- **UI/UX 개선**: 주행 중 사용성을 고려한 직관적인 UI/UX 디자인 적용
