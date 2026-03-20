# Google SSO (Auth Provider) 설정 가이드

> 📅 2026-03-19 정리

## 전체 흐름

```
Google 로그인 버튼 클릭
→ Auth Provider (Salesforce) → Google OAuth 인증
→ Callback URL로 복귀
→ Registration Handler 실행 (User/Contact 생성)
→ Force.com Site Home Action 기준으로 착지 페이지 결정
```

## 자주 빠지는 함정

| 문제 | 원인 | 해결 |
|------|------|------|
| `No_Oauth_State: State was not valid` | Google Cloud Console에 Redirect URI 미등록 | OAuth 클라이언트 → 승인된 리디렉션 URI에 `https://사이트URL/services/authcallback/Google` 추가 |
| 로그인 후 Visualforce 페이지로 착지 | Force.com Site Detail Home Action 미설정 | Home Action → `CommunitiesLanding` 으로 설정 |
| `Execute Registration As` Guest User 설정 불가 | Salesforce Lookup에서 Guest User 조회 안 됨 | Admin 권한 User로 설정 |
| Google이 LastName만 넘김 | 한국어 이름을 lastName 하나에 풀네임으로 전달 | `data.fullName` fallback 처리 필수 |
| Contact 중복 생성 | createUser 호출 시마다 새 Contact insert | Email로 기존 Contact 먼저 조회 후 없을 때만 insert |

## Registration Handler 핵심 포인트

- `sfdc_networkid` 조건 → **제거** (없으면 null 반환 → VF로 튕김)
- `Execute Registration As` → **Admin 권한 User**
- Contact 중복 방지 → 이메일로 기존 Contact 먼저 SOQL 조회
- lastName fallback → `data.fullName` 사용 (`data.displayName`은 존재하지 않는 필드)

## CSP Trusted Sites 설정

경로: `Setup → Trusted URLs → New Trusted URL`

- CSP Context는 **Experience Builder Sites**로 설정 (`All` 설정 시 본진 Lightning까지 열림)
- Google API 연동 전 반드시 선행 등록 필요
