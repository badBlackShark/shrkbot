# frozen_string_literal: true

module Bot
  class LeaderLock
    KEY = "shrkbot:bot:leader"
    TTL_MS = 6_000
    TICK_SECONDS = 1

    RENEW = <<~LUA
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("pexpire", KEYS[1], ARGV[2])
      end
      return 0
    LUA

    RELEASE = <<~LUA
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
      end
      return 0
    LUA

    def initialize
      @redis = Redis.new(url: Config.redis_url)
      @id = "#{Socket.gethostname}-#{Process.pid}-#{SecureRandom.hex(4)}"
    end

    def acquire
      sleep(TICK_SECONDS) until try_acquire
      @renewer = Thread.new { renew_loop }
    end

    def release
      @renewer&.kill
      Redis.new(url: Config.redis_url).eval(RELEASE, keys: [KEY], argv: [@id])
    rescue Redis::BaseError => e
      Rails.logger.warn("[leader_lock] release failed: #{e.class}: #{e.message}")
    end

    private

    def try_acquire
      @redis.set(KEY, @id, nx: true, px: TTL_MS)
    rescue Redis::BaseError
      false
    end

    def renew_loop
      loop do
        sleep(TICK_SECONDS)
        renew
      end
    end

    def renew
      return if @redis.eval(RENEW, keys: [KEY], argv: [@id, TTL_MS]) == 1
      Rails.logger.warn("[leader_lock] lock lost — reacquired: #{try_acquire ? "yes" : "no"}")
    rescue Redis::BaseError => e
      Rails.logger.warn("[leader_lock] renew failed: #{e.class}: #{e.message}")
    end
  end
end
