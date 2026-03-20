# Account 삭제로 인한 Contact cascade 삭제 및 복구

> 📅 2026-03-19 이슈 정리

## 문제

Contact 데이터 입력 과정에서 Account가 자동 생성되며 중복 Account 다수 발생.
중복 Account 정리를 위해 삭제했는데, Salesforce cascade 삭제 정책으로 인해 연결된 Contact까지 함께 삭제됨.

Recycle Bin에서 Contact가 Account 하위에 묶여 있어 개별 항목으로 보이지 않았음.
Salesforce Inspector에서 `IsDeleted = true` 조회 시도했으나 결과 없음.

## 해결 과정

1. Inspector의 한계 확인 → Workbench로 이동
2. `queryAll` 엔드포인트 + `ALL ROWS` 옵션으로 `IsDeleted = true`인 Contact Id 목록 추출
3. 추출한 Id 기반으로 Workbench에서 Undelete API 일괄 실행 → Contact 전체 복구 완료

## 핵심 학습

- Salesforce는 기본적으로 **Soft Delete** (휴지통 15일 보관) 방식 사용
- 표준 Account 삭제 시 연결된 Contact도 **cascade로 함께 삭제됨**
- Inspector는 `queryAll` 처리 방식 한계로 삭제된 레코드 조회 안 될 수 있음
- Workbench `queryAll` 또는 DBeaver `ALL ROWS` 키워드로 Soft Delete 레코드 조회 가능
- **다음번에는** Inspector Import Data > Undelete 기능으로 한 툴에서 처리 가능
