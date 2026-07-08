import io

import numpy as np
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from PIL import Image, UnidentifiedImageError

from paddleocr import PaddleOCR

from preprocess import phash_hex, preprocess

MAX_BYTES = 10 * 1024 * 1024

ocr = PaddleOCR(
    text_detection_model_name="PP-OCRv5_mobile_det",
    text_recognition_model_name="PP-OCRv5_mobile_rec",
    use_doc_orientation_classify=False,
    use_doc_unwarping=False,
    use_textline_orientation=False,
    lang="en",
)

app = FastAPI()


def _decode(body: bytes) -> Image.Image:
    return Image.open(io.BytesIO(body))


def _to_bgr(img: Image.Image):
    # Paddle segfaults on the negative-stride view a plain [:, :, ::-1] produces
    return np.ascontiguousarray(np.asarray(img)[:, :, ::-1])


def _run_ocr(img: Image.Image):
    results = ocr.predict(_to_bgr(img))
    texts, scores = [], []
    for res in results or []:
        t = res["rec_texts"]
        s = res["rec_scores"]
        if t:
            texts.extend(t)
            scores.extend(s or [])
    return texts, scores


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/phash")
async def phash_endpoint(request: Request):
    body = await request.body()
    if len(body) > MAX_BYTES:
        return Response(status_code=413)
    try:
        img = _decode(body)
    except UnidentifiedImageError:
        return Response(status_code=400)
    img = preprocess(img)
    return {"phash": phash_hex(img)}


@app.post("/scan")
async def scan(request: Request):
    body = await request.body()
    if len(body) > MAX_BYTES:
        return Response(status_code=413)
    try:
        img = _decode(body)
    except UnidentifiedImageError:
        return Response(status_code=400)
    img = preprocess(img)
    ph = phash_hex(img)
    texts, scores = _run_ocr(img)
    mean_conf = (sum(scores) / len(scores)) if scores else None
    return JSONResponse({
        "text": "\n".join(texts),
        "mean_conf": mean_conf,
        "n_boxes": len(texts),
        "phash": ph,
    })
