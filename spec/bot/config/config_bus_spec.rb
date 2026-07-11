# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ConfigBus do
  let(:redis) { double("redis") }

  before do
    allow(Bot::Config).to receive(:redis_url).and_return("redis://localhost:6379")
    allow(Redis).to receive(:new).and_return(redis)
    allow(redis).to receive(:publish)
  end

  describe ".repost_roles" do
    let(:set) { create(:role_set) }

    it "publishes a roles_repost event carrying the set id" do
      described_class.repost_roles(set)

      expect(redis).to have_received(:publish).with(
        described_class::CHANNEL,
        JSON.generate(type: "roles_repost", set_id: set.id)
      )
    end
  end

  describe ".post_roles" do
    let(:set) { create(:role_set) }

    it "publishes a roles_post event carrying the set id" do
      described_class.post_roles(set)

      expect(redis).to have_received(:publish).with(
        described_class::CHANNEL,
        JSON.generate(type: "roles_post", set_id: set.id)
      )
    end
  end

  describe ".remove_roles_menu" do
    let(:set) { create(:role_set) }

    it "publishes a roles_menu_remove event carrying the set id" do
      described_class.remove_roles_menu(set)

      expect(redis).to have_received(:publish).with(
        described_class::CHANNEL,
        JSON.generate(type: "roles_menu_remove", set_id: set.id)
      )
    end
  end

  describe ".delete_roles_message" do
    it "publishes a roles_message_delete event with channel and message ids" do
      described_class.delete_roles_message(channel_id: 111, message_id: 222)

      expect(redis).to have_received(:publish).with(
        described_class::CHANNEL,
        JSON.generate(type: "roles_message_delete", channel_id: 111, message_id: 222)
      )
    end
  end

  describe ".publish" do
    context "when Redis is unreachable" do
      let(:set) { create(:role_set) }

      before do
        allow(redis).to receive(:publish).and_raise(Redis::BaseConnectionError, "down")
        allow(Rails.logger).to receive(:error)
      end

      it "swallows the error and logs the dropped event" do
        expect { described_class.post_roles(set) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(a_string_including("dropping roles_post"))
      end
    end

    context "when Bot::Config.redis_url is nil" do
      let(:set) { create(:role_set) }

      before do
        allow(Bot::Config).to receive(:redis_url).and_return(nil)
      end

      it "does not instantiate Redis" do
        described_class.post_roles(set)
        expect(Redis).not_to have_received(:new)
      end

      it "logs a warning" do
        allow(Rails.logger).to receive(:warn)
        described_class.post_roles(set)
        expect(Rails.logger).to have_received(:warn).with(a_string_including("REDIS_URL not set"))
      end
    end
  end
end
