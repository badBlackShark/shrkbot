# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::LeaderLock do
  subject(:lock) { described_class.new }

  let(:redis) { instance_double(Redis) }
  let(:renewer) { instance_double(Thread) }

  before do
    allow(Bot::Config).to receive(:redis_url).and_return("redis://localhost:6379")
    allow(Redis).to receive(:new).and_return(redis)
    allow(Thread).to receive(:new).and_return(renewer)
  end

  describe "#acquire" do
    context "when the key is immediately available" do
      before do
        allow(redis).to receive(:set).and_return(true)
      end

      it "sets the key with nx: true and px: TTL_MS" do
        lock.acquire

        expect(redis).to have_received(:set).with(
          described_class::KEY,
          anything,
          nx: true,
          px: described_class::TTL_MS
        )
      end

      it "starts a renewal thread" do
        lock.acquire

        expect(Thread).to have_received(:new)
      end
    end

    context "when the key is held (set returns false twice, then truthy)" do
      let(:attempts) { [] }

      before do
        allow(lock).to receive(:sleep)
        allow(redis).to receive(:set) do
          attempts << :attempt
          attempts.size >= 3
        end
      end

      it "sleeps TICK between attempts and retries until success" do
        lock.acquire

        expect(attempts.size).to eq(3)
        expect(lock).to have_received(:sleep).with(described_class::TICK_SECONDS).exactly(2).times
      end
    end

    context "when Redis raises Redis::BaseError once, then succeeds" do
      let(:attempts) { [] }

      before do
        allow(lock).to receive(:sleep)
        allow(redis).to receive(:set) do
          attempts << :attempt
          raise Redis::BaseError, "down" if attempts.size == 1
          true
        end
      end

      it "treats the error as not-acquired, keeps retrying, does not raise" do
        expect { lock.acquire }.not_to raise_error
        expect(attempts.size).to eq(2)
      end
    end
  end

  describe "renewal tick" do
    let(:release_redis) { instance_double(Redis) }

    before do
      allow(redis).to receive(:set).and_return(true)
      allow(Redis).to receive(:new).and_return(redis, release_redis)
    end

    context "when eval returns 1 (lock held)" do
      before do
        allow(Thread).to receive(:new).and_yield.and_return(renewer)
        allow(lock).to receive(:sleep).with(described_class::TICK_SECONDS).and_invoke(
          ->(_) {},
          ->(_) { raise StopIteration }
        )
        allow(redis).to receive(:eval).and_return(1)
      end

      it "renews via the RENEW Lua script with correct keys and argv" do
        lock.acquire

        expect(redis).to have_received(:eval).with(
          described_class::RENEW,
          keys: [described_class::KEY],
          argv: [anything, described_class::TTL_MS]
        )
      end
    end

    context "when eval returns 0 (lock lost)" do
      before do
        allow(Thread).to receive(:new).and_yield.and_return(renewer)
        allow(lock).to receive(:sleep).with(described_class::TICK_SECONDS).and_invoke(
          ->(_) {},
          ->(_) { raise StopIteration }
        )
        allow(redis).to receive(:eval).and_return(0)
        allow(redis).to receive(:set).and_return(true)
        allow(Rails.logger).to receive(:warn)
      end

      it "attempts re-acquire and logs a warning" do
        lock.acquire

        expect(Rails.logger).to have_received(:warn).with(a_string_including("lock lost"))
        expect(redis).to have_received(:set).with(
          described_class::KEY,
          anything,
          nx: true,
          px: described_class::TTL_MS
        ).at_least(:twice)
      end
    end

    context "when eval raises Redis::BaseError" do
      before do
        allow(Thread).to receive(:new).and_yield.and_return(renewer)
        allow(lock).to receive(:sleep).with(described_class::TICK_SECONDS).and_invoke(
          ->(_) {},
          ->(_) { raise StopIteration }
        )
        allow(redis).to receive(:eval).and_raise(Redis::BaseError, "connection lost")
        allow(Rails.logger).to receive(:warn)
      end

      it "logs a warning and does not raise" do
        expect { lock.acquire }.not_to raise_error
        expect(Rails.logger).to have_received(:warn).with(a_string_including("renew failed"))
      end
    end
  end

  describe "#release" do
    let(:release_redis) { instance_double(Redis) }

    before do
      allow(redis).to receive(:set).and_return(true)
      allow(Redis).to receive(:new).and_return(redis, release_redis)
      allow(renewer).to receive(:kill)
      lock.acquire
    end

    it "kills the renewer thread and runs the RELEASE Lua script" do
      allow(release_redis).to receive(:eval)

      lock.release

      expect(renewer).to have_received(:kill)
      expect(release_redis).to have_received(:eval).with(
        described_class::RELEASE,
        keys: [described_class::KEY],
        argv: [anything]
      )
    end

    context "when Redis raises on release" do
      before do
        allow(release_redis).to receive(:eval).and_raise(Redis::BaseError, "down")
        allow(Rails.logger).to receive(:warn)
      end

      it "logs a warning and does not raise" do
        expect { lock.release }.not_to raise_error
        expect(Rails.logger).to have_received(:warn).with(a_string_including("release failed"))
      end
    end
  end
end
