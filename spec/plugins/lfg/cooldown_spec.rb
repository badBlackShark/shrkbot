# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::Cooldown do
  subject(:cooldown) { described_class.new }

  let(:base_time) { Time.at(1_000_000) }
  let(:guild_id) { 1 }
  let(:user_id) { 2 }

  describe "#remaining" do
    context "with no prior start" do
      it "returns 0" do
        expect(cooldown.remaining(guild_id:, user_id:, at: base_time)).to eq(0)
      end
    end

    context "after start" do
      before do
        cooldown.start(guild_id:, user_id:, at: base_time, ttl: 300)
      end

      it "returns the full ttl right after start" do
        expect(cooldown.remaining(guild_id:, user_id:, at: base_time)).to be_within(1).of(300)
      end

      it "returns 0 once the ttl has fully elapsed" do
        expect(cooldown.remaining(guild_id:, user_id:, at: base_time + 300)).to eq(0)
      end

      it "returns the remaining seconds partway through the ttl" do
        expect(cooldown.remaining(guild_id:, user_id:, at: base_time + 100)).to be_within(1).of(200)
      end
    end

    context "with a different guild" do
      before do
        cooldown.start(guild_id:, user_id:, at: base_time, ttl: 300)
      end

      it "tracks the cooldown independently" do
        expect(cooldown.remaining(guild_id: 99, user_id:, at: base_time)).to eq(0)
      end
    end

    context "with a different user" do
      before do
        cooldown.start(guild_id:, user_id:, at: base_time, ttl: 300)
      end

      it "tracks the cooldown independently" do
        expect(cooldown.remaining(guild_id:, user_id: 99, at: base_time)).to eq(0)
      end
    end

    context "when the entry has expired" do
      before do
        cooldown.start(guild_id:, user_id:, at: base_time, ttl: 300)
        cooldown.remaining(guild_id:, user_id:, at: base_time + 301)
      end

      it "sweeps the expired entry so remaining stays 0 on a later check" do
        expect(cooldown.remaining(guild_id:, user_id:, at: base_time + 500)).to eq(0)
      end
    end
  end

  describe "#start" do
    it "sets an expiry that #remaining honors" do
      cooldown.start(guild_id:, user_id:, at: base_time, ttl: 60)

      expect(cooldown.remaining(guild_id:, user_id:, at: base_time)).to be_within(1).of(60)
    end

    it "overwrites a prior expiry for the same key" do
      cooldown.start(guild_id:, user_id:, at: base_time, ttl: 60)
      cooldown.start(guild_id:, user_id:, at: base_time, ttl: 600)

      expect(cooldown.remaining(guild_id:, user_id:, at: base_time)).to be_within(1).of(600)
    end
  end
end
