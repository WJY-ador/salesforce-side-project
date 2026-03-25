# Cloud Run 성능 개선 — 이미지 리사이즈 적용

> 작성일: 2026-03-24 | 출처: [Notion](https://www.notion.so/32d1241404c381ccb98cddd7a150f2cd)

---

## 문제

영수증 3장 처리 시 20초 이상 소요.

**원인:** 폰 카메라 사진(3~8MB) 원본을 base64 인코딩 후 Gemini에 그대로 전송.

---

## 해결: `resize_image()` 함수 추가

`main.py`에 Pillow 기반 리사이즈 함수 추가 (max 1024px).

```python
def resize_image(image_bytes: bytes, max_size: int = 1024) -> bytes:
    img = Image.open(io.BytesIO(image_bytes))
    img.thumbnail((max_size, max_size), Image.LANCZOS)
    buf = io.BytesIO()
    fmt = img.format or "JPEG"
    img.save(buf, format=fmt)
    return buf.getvalue()
```

`requirements.txt`에 `Pillow` 추가 후 Cloud Run 재배포.

**결과:** 20초 → 5~8초 (예상)

---

## GitHub 코드 통합 (같은 날 작업)

Cloud Run Python 코드가 GCP에만 존재하여 버전 관리가 안 되는 문제 해결.

**과정:**
1. GCS에서 소스 zip 추출 (`gcloud storage cp`)
2. Cloud Shell에서 git init → GitHub repo에 merge
3. `cloud-run/` 폴더로 정리 후 push

**최종 repo 구조:**
```
salesforce-side-project/
├── force-app/     # Salesforce 코드 (Apex, LWC)
├── cloud-run/     # Python FastAPI (receipt-extractor)
│   ├── main.py
│   ├── requirements.txt
│   └── Procfile
└── ...
```

---

## 다음 단계

- [ ] 속도 테스트 (리사이즈 후 실제 처리 시간 측정)
- [ ] BigQuery 연동 설계 및 구현
