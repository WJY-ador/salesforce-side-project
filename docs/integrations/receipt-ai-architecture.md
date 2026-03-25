# 영수증 AI 자동 처리 시스템 — 아키텍처 & 구현 회고

> 작성일: 2026-03-23 | 출처: [Notion](https://www.notion.so/32c1241404c380e0936cd6aef24fc149)

---

## 개요

영수증 이미지를 AI가 읽고 Salesforce 비용 레코드에 자동 반영하는 시스템.
단순 OCR을 넘어 **여러 영수증을 하루 단위 비용으로 해석하고, 분류·요약·이상 탐지를 수행하는 AI 기반 비용 분석 시스템.**

---

## 전체 처리 흐름

```
Salesforce (Apex)
  → 이미지 파일을 Base64로 인코딩
  → Cloud Run (Python / FastAPI)
      → Vertex AI Gemini 멀티모달 호출 (asyncio.gather 병렬 처리)
          → 영수증 이미지 분석
          → JSON 구조로 반환
            { store_name, transaction_date, total_amount, items[],
              category, summary, is_anomaly, anomaly_reason }
  → Apex에서 JSON 파싱
  → Expense__c 필드 업데이트
```

---

## 아키텍처 결정사항

### Expense 데이터 모델
```
Expense = 영수증 1장  ❌  (초기 설계)
Expense = 하루 단위 비용 묶음  ✅  (최종 확정)
```
여러 영수증 → 하나의 Expense에 묶음. 파일 여러 개를 한 Expense에서 관리.

### 처리 방식: Trigger 자동 vs 버튼 기반
- **Trigger 자동:** 파일 1개마다 API 호출 → 불필요한 비용 + 중간 상태 재계산 문제
- **버튼 기반 ✅:** 파일 다 올리고 버튼 클릭 → 1회 batch 처리

### 정규화 vs 요약 중심
```
Expense_Item 개별 레코드  ❌  (레코드 폭증, 사용성 낮음)
ItemsSummary 텍스트 저장  ✅  (요약 중심, 실무에 적합)
```

---

## Expense__c 필드 구성

| 필드 API명 | 타입 | 용도 |
|---|---|---|
| `TotalAmount__c` | Currency | 전체 영수증 합산 금액 |
| `ItemsSummary__c` | Long Text | 영수증별 품목 요약 |
| `StoreName__c` | Text | 첫 번째 영수증 상호명 |
| `TransactionDate__c` | DateTime | 첫 번째 영수증 거래 일시 |
| `AIProcessed__c` | Checkbox | AI 처리 완료 여부 |
| `RawJSON__c` | Long Text | AI 응답 원본 JSON |
| `Category__c` | Picklist | 비용 성격 (식비/교통비/숙박비/회의비/접대비/소모품비/기타) |
| `Summary__c` | Text | AI 생성 한 줄 요약 (`/` 로 합산) |
| `IsAnomaly__c` | Checkbox | 이상 거래 여부 (하나라도 true면 true) |
| `AnomalyReason__c` | Text | 이상 판단 이유 (`\|` 로 합산) |

---

## 처리 프로세스 상세

1. **사용자:** Expense 생성 → 영수증 이미지 여러 장 첨부 → [영수증 처리] 버튼 클릭
2. **LWC (ReceiptProcessAction):** `checkDuplicateFiles()` → 중복 팝업 → `processExpense()` 호출
3. **Apex (ReceiptExtractorService):** 첨부 파일 조회(ContentDocumentLink → ContentVersion) → Base64 인코딩 → `/extract-receipts-batch` POST 1회
4. **Cloud Run:** `asyncio.gather()`로 파일별 병렬 Vertex AI 호출 → JSON 배열 반환
5. **Apex 응답 처리:** TotalAmount 합산, Summary/IsAnomaly/AnomalyReason 집계 → Expense__c 업데이트
6. **LWC:** `CloseActionScreenEvent` → `NavigationMixin`으로 Expense 레코드 redirect

---

## 성능 이력

| 시점 | 처리 시간 (5파일 기준) | 방식 |
|---|---|---|
| 초기 | ~20초 | 파일 원본 순차 처리 |
| 이미지 리사이즈 적용 후 | ~5~8초 | max 1024px resize + 병렬 처리 |

→ 2026.03.24 `resize_image()` 함수 추가 및 배치 엔드포인트로 병렬 처리 전환

---

## 교훈

- **자동화는 항상 좋은 것이 아니다** — Trigger 기반보다 버튼 기반이 더 명확하고 안정적
- **데이터 모델이 가장 중요하다** — 모델 정의가 전체 구조를 결정
- **정규화보다 사용성 우선** — 세부 품목 레코드화보다 요약 중심이 실무에 적합
- **전체 재계산이 가장 안전하다** — 누적 방식보다 매번 전체 재처리
