FROM python:3.13-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends libgomp1 libglib2.0-0 libgl1 && \
    rm -rf /var/lib/apt/lists/*

ENV OMP_NUM_THREADS=2 PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY service.py preprocess.py ./

RUN useradd -r -u 1001 -m ocr
USER ocr
# Pre-create the model cache so a named volume mounted here inherits ocr's
# ownership (fresh volumes otherwise mount root-owned and downloads fail).
RUN mkdir -p /home/ocr/.paddlex

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=180s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=4)"]
CMD ["uvicorn", "service:app", "--host", "0.0.0.0", "--port", "8000"]
