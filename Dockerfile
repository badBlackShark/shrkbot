FROM crystallang/crystal:0.36.1

RUN mkdir /app
COPY . /app
WORKDIR /app

RUN shards install
RUN shards build --release --no-debug
ENTRYPOINT /app/bin/shrkbot
