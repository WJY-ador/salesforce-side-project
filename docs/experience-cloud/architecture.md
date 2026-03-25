# Experience Cloud 전체 아키텍처 구조

> 📅 2026-03-18 정리

## 전체 구조

```
[외부 파트너/고객]
        ↓
[Experience Cloud 사이트]
├── 로그인 페이지 (Guest User 영역)
│   └── LWC 커스텀 로그인 컴포넌트
├── 파트너 페이지들 (Partner User 영역)
│   ├── Home
│   ├── Opportunities
│   ├── Cases
│   └── Reports
└── SSO (Okta/Azure/Google)
        ↓
[Salesforce 본진]
├── Account / Contact
├── Opportunity / Case
├── Profile / Permission Set
└── OWD / Sharing Rules
```

## 사용자 유형

| 유형 | 영역 | 설명 |
|------|------|------|
| Guest User | 로그인 페이지 | 로그인 전 비인증 사용자 |
| Partner Community User | Ex Cloud 내부 | 로그인 후 파트너 |
| Internal User (Admin) | 본진 | Salesforce 내부 직원 |

## 본진 vs Ex Cloud 설정 분리

| 항목 | 본진 | Ex Cloud |
|------|------|----------|
| 페이지 레이아웃 | Object Manager > Page Layout | Builder에서 별도 구성 |
| 레코드 페이지 | Lightning App Builder | Builder (Community용) |
| 컴포넌트 | Lightning App Builder | Experience Builder |
| 권한 | Profile / Permission Set | 동일 + Builder 페이지 권한 추가 |

> ⭐ 본진에서 됐다고 Ex Cloud에서 되는 게 아님. 항상 따로 확인!

## 데이터 보안 구조

```
OWD (Organization-Wide Default)
└── Default External Access: Private
        ↓
Sharing Set (Customer Community 라이선스용)
└── User:Account = Object:Account 매핑
        ↓
Sharing Rule (광역 공유)
└── 특정 그룹/역할에 Read Only 또는 Read/Write
        ↓
Account Relationship (파트너사간 수평 공유)
└── A지점 ↔ B지점 협업 데이터 공유
```

## 실무에서 자주 막히는 부분 TOP 6

1. **Shadow DOM** — LWC CSS 스타일 상속 안 됨, `:host` 필수
2. **Guest User 권한** — Object, Field 레벨까지 전부 체크
3. **CSP** — 외부 리소스 전부 차단, Trusted Sites 등록 필요
4. **본진 vs Ex Cloud 분리** — 본진에서 됐다고 Ex Cloud에서 되는 게 아님
5. **OWD + Sharing 설정** — Sharing Set, Sharing Rule 복잡
6. **페이지 레이아웃** — Object마다, Record Type마다 따로 설정 필요

## Ex Cloud 배포 제한

```
일반 Apex/LWC 코드    → Change Set / DevOps Center로 배포 가능
Ex Cloud 사이트 자체  → 배포 불가. 운영에서 직접 처음부터 만들어야 함
```
