# shrkbot OCR sidecar

PP-OCRv5_mobile English OCR + perceptual hashing sidecar for shrkbot image scanning. Aux preprocessing (orientation classify, unwarping, textline orientation) is disabled. Classification happens in Ruby; this service is dumb: OCR + phash only.

## API

All `POST` endpoints accept raw image bytes in the request body (not multipart). Responses are JSON. Requests over 10 MB → 413. Undecodable image → 400.

| Endpoint | Method | Response |
|---|---|---|
| `/health` | GET | `{"status": "ok"}` |
| `/phash` | POST | `{"phash": "<16-char hex>"}` |
| `/scan` | POST | `{"text": str, "mean_conf": float\|null, "n_boxes": int, "phash": str}` |

`mean_conf` is null when no text boxes are detected. `text` is newline-joined recognized lines.

## Build & run

```sh
docker build -t shrkbot-ocr ocr/
docker run --rm -p 8000:8000 --cpus 2 shrkbot-ocr
```

`OMP_NUM_THREADS=2` is baked into the image; pair with `--cpus 2` to avoid thread contention.

## Tests

```sh
pytest ocr/tests
```

No paddleocr needed for the test suite — `service.py` is never imported by tests.

## Benchmarking

```sh
python paddle_bakeoff.py --images ./images --truth ground_truth.json
```

`make_variants.py` regenerates degraded image variants used for bakeoff scoring.

## Privacy

Images are processed in memory only. They are never written to disk. This is a binding constraint: do not add file-path handling to `service.py`.

## Version pin

`paddlepaddle` must stay at `3.2.2`. Version `3.3.x` breaks CPU inference (`ConvertPirAttribute2RuntimeAttribute` not supported in PIR+oneDNN mode, upstream issue Paddle #77340).
