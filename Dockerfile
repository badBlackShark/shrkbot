FROM crystallang/crystal:latest

RUN mkdir /app
COPY . /app
WORKDIR /app

RUN shards install
RUN shards build --release --no-debug
ENTRYPOINT /app/bin/shrkbot
