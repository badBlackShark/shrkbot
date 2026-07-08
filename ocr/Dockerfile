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

EXPOSE 8000
CMD ["uvicorn", "service:app", "--host", "0.0.0.0", "--port", "8000"]
