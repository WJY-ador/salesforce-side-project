import asyncio
import base64
import io
import json
import os

from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
from google import genai
from google.genai.types import Part, GenerateContentConfig
from PIL import Image

app = FastAPI()

PROJECT_ID = os.environ["GCP_PROJECT"]
LOCATION = os.environ.get("GCP_REGION", "us-central1")

client = genai.Client(
      vertexai=True,
      project=PROJECT_ID,
      location=LOCATION,
  )

MODEL = os.environ.get("MODEL_NAME", "gemini-2.5-flash")

PROMPT = """
  You are a receipt OCR and structured data extraction system.

    Extract data from exactly ONE receipt image and return ONLY valid JSON.

    Output schema:
    {
      "store_name": string,
      "transaction_date": string,
      "total_amount": number,
      "items": [
        {
          "name": string,
          "quantity": number,
          "price": number
        }
      ],
      "category": string,
      "summary": string,
      "is_anomaly": boolean,
      "anomaly_reason": string
    }

    Rules:
    - Return ONLY one JSON object
    - Do not return an array
    - transaction_date must be in ISO 8601 format: YYYY-MM-DD HH:MM:SS
    - total_amount must be a number only
    - Extract all visible item lines whenever possible
    - If item lines are partially unreadable, still return the readable ones
    - If no items are visible, return an empty array
    - category must be one of: 식비, 교통비, 숙박비, 회의비, 접대비, 소모품비, 기타
    - summary must be a one-sentence Korean description of the receipt
    - is_anomaly must be true if the expense seems unusual or suspicious, otherwise false
    - anomaly_reason must explain why if is_anomaly is true, otherwise null
    - If a field is missing, use null
    - No explanation, no markdown, no extra text
    """

class ReceiptRequest(BaseModel):
      image_base64: str
      mime_type: str = "image/jpeg"

class BatchReceiptRequest(BaseModel):
      receipts: List[ReceiptRequest]

def parse_response_text(text: str) -> dict:
      text = text.strip()
      if text.startswith("```"):
          text = text.replace("```json", "").replace("```", "").strip()
      return json.loads(text)

def resize_image(image_bytes: bytes, max_size: int = 1024) -> bytes:
      img = Image.open(io.BytesIO(image_bytes))
      img.thumbnail((max_size, max_size), Image.LANCZOS)
      buf = io.BytesIO()
      fmt = img.format or "JPEG"
      img.save(buf, format=fmt)
      return buf.getvalue()

@app.get("/")
def root():
      return {"status": "ok"}

@app.post("/extract-receipt")
def extract_receipt(req: ReceiptRequest):
      image_bytes = resize_image(base64.b64decode(req.image_base64))

      response = client.models.generate_content(
          model=MODEL,
          contents=[
              PROMPT,
              Part.from_bytes(data=image_bytes, mime_type=req.mime_type),
          ],
          config=GenerateContentConfig(temperature=0),
      )

      return parse_response_text(response.text)

async def analyze_one(image_bytes: bytes, mime_type: str) -> dict:
      image_bytes = resize_image(image_bytes)
      response = await client.aio.models.generate_content(
          model=MODEL,
          contents=[
              PROMPT,
              Part.from_bytes(data=image_bytes, mime_type=mime_type),
          ],
          config=GenerateContentConfig(temperature=0),
      )
      return parse_response_text(response.text)

@app.post("/extract-receipts-batch")
  async def extract_receipts_batch(req: BatchReceiptRequest):
      tasks = [
          analyze_one(base64.b64decode(r.image_base64), r.mime_type)
          for r in req.receipts
      ]
      results = await asyncio.gather(*tasks, return_exceptions=True)

      output = []
      for r in results:
          if isinstance(r, Exception):
              output.append({"error": str(r)})
          else:
              output.append(r)

      return output