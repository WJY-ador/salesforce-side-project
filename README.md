# Salesforce Side Project

Salesforce Dev Org에서 직접 구현하며 쌓아가는 LWC 컴포넌트, Apex 클래스, 외부 연동, 아키텍처 문서 모음입니다.

![API-v66.0](https://img.shields.io/badge/API-v66.0-00A1E0?style=flat-square&logo=salesforce&logoColor=white) ![LWC](https://img.shields.io/badge/LWC-FF6B35?style=flat-square&logoColor=white) ![Apex](https://img.shields.io/badge/Apex-1798C1?style=flat-square&logo=salesforce&logoColor=white) ![Experience Cloud](https://img.shields.io/badge/Experience_Cloud-032D60?style=flat-square&logo=salesforce&logoColor=white) ![Cloud Run](https://img.shields.io/badge/Cloud_Run-4285F4?style=flat-square&logo=googlecloud&logoColor=white) ![Vertex AI](https://img.shields.io/badge/Vertex_AI-34A853?style=flat-square&logo=googlecloud&logoColor=white)

## 목차

- [구현 목록](#구현-목록)
- [영수증 AI 자동 처리](#영수증-ai-자동-처리)
- [문서](#문서)
- [시작하기](#시작하기)
- [프로젝트 구조](#프로젝트-구조)

## 구현 목록

### LWC

| 컴포넌트 | 설명 | 상태 |
|:--|:--|:--:|
| `customLogin` | Experience Cloud 커스텀 로그인 페이지 | 완료 |
| `accountActivityHeatmap` | Account의 최근 활동(Task/Event) 밀도를 보여주는 GitHub 스타일 히트맵 | 완료 |
| `receiptProcessAction` | Expense 레코드에서 첨부한 영수증을 AI로 일괄 처리하는 Quick Action | 완료 |
| `kakaoMap` | Kakao Maps API를 활용한 지도 표시와 주소 자동완성 | 진행 중 |

### Apex

| 클래스 / 트리거 | 설명 |
|:--|:--|
| `CustomLoginController` | Experience Cloud 로그인 처리 |
| `AccountActivityHeatmapController` | 히트맵용 Task/Event 조회 |
| `KakaoMapController` | Kakao Maps API 키 제공 |
| `ReceiptExtractorService`, `ReceiptExtractorQueueable` | 영수증 이미지를 Cloud Run으로 보내고 결과를 Expense에 반영 |
| `ContentDocumentLinkTrigger` | 파일 첨부 이벤트 처리 |

## 영수증 AI 자동 처리

영수증 이미지를 AI가 읽고 Salesforce 비용 레코드(`Expense__c`)에 자동 반영하는 시스템입니다.
단순 OCR을 넘어, 여러 장의 영수증을 하루 단위 비용으로 묶어 분류, 요약, 이상 거래 탐지까지 수행합니다.

```
Salesforce (Apex)
  └─ 첨부 이미지를 Base64로 인코딩해 1회 요청
      └─ Cloud Run (Python / FastAPI)
          └─ Vertex AI Gemini 멀티모달 호출 (파일별 병렬 처리)
              └─ JSON 반환: 상호명, 거래일시, 금액, 품목, 분류, 요약, 이상 여부
  └─ Apex에서 결과를 집계해 Expense__c 업데이트
```

**설계 결정**

- **데이터 모델**: Expense 1건 = 영수증 1장이 아니라 **하루 단위 비용 묶음**으로 정의
- **처리 방식**: 파일마다 Trigger로 호출하지 않고, 버튼 클릭 시 1회 배치 처리
- **품목 저장**: 품목별 레코드로 정규화하지 않고 요약 텍스트로 저장해 사용성 우선

**성능**: 이미지 리사이즈(최대 1024px)와 병렬 처리를 적용해 5장 기준 처리 시간을 약 20초에서 5~8초로 단축했습니다.

자세한 내용은 [아키텍처 문서](docs/integrations/receipt-ai-architecture.md)와 [성능 개선 기록](docs/integrations/cloud-run-performance.md)을 참고하세요.

## 문서

| 문서 | 내용 |
|:--|:--|
| [experience-cloud/architecture.md](docs/experience-cloud/architecture.md) | Experience Cloud 전체 아키텍처 |
| [experience-cloud/sales-dashboard-implementation.md](docs/experience-cloud/sales-dashboard-implementation.md) | Sales Dashboard LWC 구현 기록 (KPI 설계, 모달, 버그 수정) |
| [experience-cloud/issue-log-20260325.md](docs/experience-cloud/issue-log-20260325.md) | Gemini CLI 실행 환경 오류 해결 기록 |
| [integrations/google-sso.md](docs/integrations/google-sso.md) | Google SSO (Auth Provider) 설정과 트러블슈팅 |
| [integrations/receipt-ai-architecture.md](docs/integrations/receipt-ai-architecture.md) | 영수증 AI 자동 처리 아키텍처와 회고 |
| [integrations/cloud-run-performance.md](docs/integrations/cloud-run-performance.md) | Cloud Run 이미지 리사이즈 성능 개선 |
| [data-management/cascade-delete-recovery.md](docs/data-management/cascade-delete-recovery.md) | Account 삭제로 함께 삭제된 Contact 복구 |

## 시작하기

### 사전 준비

- Salesforce Dev Org (Partner Central Enhanced)
- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`)
- VS Code + Salesforce Extension Pack
- Node.js (LWC 단위 테스트, Lint 실행 시)

### 배포

```bash
sf org login web --alias devOrg --set-default

# 전체 배포
sf project deploy start --source-dir force-app

# 특정 컴포넌트만 배포
sf project deploy start --source-dir force-app/main/default/lwc/kakaoMap
```

### 테스트와 Lint

```bash
npm install
npm run test:unit   # LWC Jest 테스트
npm run lint        # ESLint
```

## 프로젝트 구조

```
salesforce-side-project/
├── force-app/main/default/
│   ├── classes/        # Apex 클래스
│   ├── lwc/            # LWC 컴포넌트
│   └── triggers/       # Apex 트리거
├── cloud-run/          # 영수증 분석 서버 (FastAPI + Vertex AI)
├── docs/
│   ├── experience-cloud/
│   ├── integrations/
│   └── data-management/
└── scripts/            # Anonymous Apex, SOQL 스크립트
```
