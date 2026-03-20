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
