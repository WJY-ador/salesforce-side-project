<<<<<<< HEAD
<<<<<<< HEAD
# Salesforce DX Project: Next Steps

Now that you’ve created a Salesforce DX project, what’s next? Here are some documentation resources to get you started.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
=======
# Salesforce Side Project

Salesforce Dev Org에서 직접 구현하며 쌓아가는 LWC 컴포넌트, Apex 클래스, 아키텍처 문서 모음입니다.

---

## 📁 구조

```
salesforce-side-project/
├── force-app/
│   └── main/
│       └── default/
│           ├── lwc/               # LWC 컴포넌트
│           │   ├── kakaoMap/      # 카카오맵 API 연동
│           │   └── customLogin/   # LWC 커스텀 로그인
│           └── classes/           # Apex 클래스
├── docs/
│   ├── experience-cloud/          # Experience Cloud 아키텍처, 설정
│   ├── apex/                      # Apex 공부 정리
│   ├── data-management/           # 데이터 관리, 이슈 정리
│   └── integrations/              # Google SSO, 외부 API 연동
└── README.md
```

---

## 🛠️ 구현 목록

### LWC 컴포넌트
| 컴포넌트 | 설명 | 상태 |
|---------|------|------|
| kakaoMap | Kakao Maps API를 활용한 지도 표시 + 주소 자동완성 | 🔄 진행 중 |
| customLogin | Experience Cloud 커스텀 로그인 페이지 | ✅ 완료 |

### 문서
| 문서 | 설명 |
|------|------|
| experience-cloud/architecture.md | Ex Cloud 전체 아키텍처 구조 |
| integrations/google-sso.md | Google SSO 설정 및 트러블슈팅 |
| data-management/cascade-delete-recovery.md | Account 삭제로 인한 Contact cascade 삭제 복구 |

---

## 🔧 환경
- Salesforce Dev Org (Partner Central Enhanced)
- Salesforce CLI (sf)
- VS Code + Salesforce Extension Pack

---

## 📦 배포 방법

```bash
# LWC 컴포넌트 배포
sf project deploy start --source-dir force-app/main/default/lwc/kakaoMap

# Apex 클래스 배포
sf project deploy start --source-dir force-app/main/default/classes
```
>>>>>>> de16ed3c9ecde79e1cb337d17457305211b00cbe
=======
# Salesforce Side Project

Salesforce Dev Org에서 직접 구현하며 쌓아가는 LWC 컴포넌트, Apex 클래스, 아키텍처 문서 모음입니다.

---

## 📁 구조

```
salesforce-side-project/
├── force-app/
│   └── main/
│       └── default/
│           ├── lwc/                       # LWC 컴포넌트
│           │   ├── accountActivityHeatmap/ # Account 활동 히트맵 (Task/Event)
│           │   ├── kakaoMap/              # 카카오맵 API 연동
│           │   └── customLogin/           # LWC 커스텀 로그인
│           └── classes/                   # Apex 클래스
│               └── AccountActivityHeatmapController.cls
├── docs/
│   ├── experience-cloud/          # Experience Cloud 아키텍처, 설정
│   ├── apex/                      # Apex 공부 정리
│   ├── data-management/           # 데이터 관리, 이슈 정리
│   └── integrations/              # Google SSO, 외부 API 연동
└── README.md
```

---

## 🛠️ 구현 목록

### LWC 컴포넌트
| 컴포넌트 | 설명 | 상태 |
|---------|------|------|
| accountActivityHeatmap | Account의 최근 활동(Task/Event) 밀도를 보여주는 GitHub 스타일 히트맵 | ✅ 완료 |
| kakaoMap | Kakao Maps API를 활용한 지도 표시 + 주소 자동완성 | 🔄 진행 중 |
| customLogin | Experience Cloud 커스텀 로그인 페이지 | ✅ 완료 |

### 문서
| 문서 | 설명 |
|------|------|
| experience-cloud/architecture.md | Ex Cloud 전체 아키텍처 구조 |
| experience-cloud/issue-log-20260325.md | google-genai 패키지 경로 및 .zshrc 구문 오류 해결 (Gemini CLI) |
| experience-cloud/sales-dashboard-implementation.md | Sales Dashboard LWC 구현 기록 (KPI 설계, salesDashboardModal, 버그수정) | ✅ 완료 |
| integrations/google-sso.md | Google SSO 설정 및 트러블슈팅 |
| integrations/receipt-ai-architecture.md | 영수증 AI 자동 처리 시스템 아키텍처 (Apex + Cloud Run + Vertex AI) | ✅ 완료 |
| integrations/cloud-run-performance.md | Cloud Run 이미지 리사이즈 성능 개선 (20초 → 5~8초) | ✅ 완료 |
| data-management/cascade-delete-recovery.md | Account 삭제로 인한 Contact cascade 삭제 복구 |

---

## 📝 이슈 로그 (Issue Log)

<details>
<summary><b>2026.03.25 (google-genai 패키지 경로 및 .zshrc 구문 오류 해결)</b></summary>

- **시작포인트 (Starting point)**
  - `gemini` alias 실행 시 `google-genai` 패키지를 찾지 못하는 모듈 로드 문제 발생.
  - `source ~/.zshrc` 시 `command not found: n#` 에러가 발생하며 셸 설정이 정상적으로 로드되지 않음.
- **과정 (Process)**
  - **분석:** `which python3` 확인 결과 alias가 시스템 Python을 호출하고 있었으나, 패키지는 가상환경(`gemini-env`)에만 설치된 상태임을 파악.
  - **식별:** `.zshrc` 파일 내에 줄바꿈 대신 `\n` 리터럴 문자가 포함되어 구문 오류를 일으키는 지점 발견.
  - **조치:** `gemini` alias를 가상환경의 Python 절대 경로로 수정하고, `.zshrc` 내의 불필요한 문자를 제거하여 정리.
- **챌린지 (Challenges)**
  - **환경 격리:** 시스템 Python과 가상환경 간의 라이브러리 인식 차이로 인해 설치 여부와 실행 환경이 일치하지 않는 전형적인 경로 문제 발생.
  - **설정 로드 실패:** 상단의 구문 오류로 인해 하단의 수정 사항이 반영되지 않아 즉각적인 확인이 어려웠음.
- **결과 (Results)**
  - `gemini` 명령어가 가상환경의 패키지를 정상 로드하여 실행됨.
  - `source ~/.zshrc` 시 오류 없이 클린하게 로드되어 셸 환경 안정화.
- **느낀점 (Learnings/Reflections)**
  - 가상환경 기반의 CLI 도구는 alias 설정 시 절대 경로를 명시하는 것이 가장 안전함.
  - 설정 파일 수정 시 눈에 보이지 않는 특수 문자나 잘못된 이스케이프가 없는지 정밀한 검토가 필요함.

</details>

---

## 🔧 환경
- Salesforce Dev Org (Partner Central Enhanced)
- Salesforce CLI (sf)
- VS Code + Salesforce Extension Pack

---

## 📦 배포 방법

```bash
# LWC 컴포넌트 배포
sf project deploy start --source-dir force-app/main/default/lwc/kakaoMap

# Apex 클래스 배포
sf project deploy start --source-dir force-app/main/default/classes
```
>>>>>>> aff755226626506b6fc7310545f70c966e0f9e90
