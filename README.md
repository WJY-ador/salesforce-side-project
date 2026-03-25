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
