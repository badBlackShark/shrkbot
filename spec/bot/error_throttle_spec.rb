# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ErrorThrottle do
  let(:throttle) { described_class.new }
  let(:key) { ["ActiveRecord::ConnectionTimeoutError", "event Bot::RoleSync"] }
  let(:now) { Time.current }

  describe "#admit" do
    subject(:admit) { throttle.admit(key, at: now) }

    context "with an unseen key" do
      it "admits the report with nothing suppressed" do
        expect(admit).to eq(0)
      end
    end

    context "with a second report inside the window" do
      before { throttle.admit(key, at: now) }

      it "throttles it" do
        expect(throttle.admit(key, at: now + 1.second)).to be_nil
      end
    end

    context "with a different key inside the window" do
      before { throttle.admit(key, at: now) }

      it "admits it, since throttling is per error class and source" do
        expect(throttle.admit(["JSON::ParserError", "event Bot::RoleSync"], at: now)).to eq(0)
      end
    end

    context "with a storm followed by the window elapsing" do
      before do
        throttle.admit(key, at: now)
        5.times { |i| throttle.admit(key, at: now + i.seconds) }
      end

      it "admits the next report and hands back how many were suppressed" do
        expect(throttle.admit(key, at: now + described_class::WINDOW + 1.second)).to eq(5)
      end
    end

    context "with a quiet window after a storm" do
      before do
        throttle.admit(key, at: now)
        3.times { throttle.admit(key, at: now) }
        throttle.admit(key, at: now + described_class::WINDOW + 1.second)
      end

      it "resets the suppressed count once it has been reported" do
        expect(throttle.admit(key, at: now + (described_class::WINDOW * 2) + 2.seconds)).to eq(0)
      end
    end
  end

  describe ".instance" do
    subject(:instance) { described_class.instance }

    it "is memoised so throttling state is shared process-wide" do
      expect(instance).to be(described_class.instance)
    end
  end
end
