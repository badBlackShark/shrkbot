# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::EventSubSubscriptions do
  let(:subscriptions) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Twitch::Client) }

  def fixture(name)
    JSON.parse(Rails.root.join("spec/fixtures/integrations/twitch/#{name}.json").read)
  end

  describe "#all" do
    subject(:all) { subscriptions.all }

    before do
      allow(client).to receive(:get_all) { |*_args, **_kwargs, &block| block.call(fixture("eventsub_subscriptions")) }
    end

    it "lists every page of the app's subscriptions" do
      all

      expect(client).to have_received(:get_all).with("/eventsub/subscriptions")
    end

    it "returns nothing for an app with no subscriptions" do
      expect(all).to eq([])
    end

    context "with subscriptions" do
      before do
        allow(client).to receive(:get_all) { |*_args, **_kwargs, &block| block.call(fixture("eventsub_subscriptions_handwritten")) }
      end

      it "maps a subscription" do
        expect(all.first).to eq(
          Integrations::Twitch::EventSubSubscription.new(
            id: "26b1c993-bfcf-44d9-b876-379dacafe75a",
            type: "stream.online",
            version: "1",
            status: "enabled",
            condition: {"broadcaster_user_id" => "141981764"},
            callback: "https://shrkbot.test/webhooks/twitch"
          )
        )
      end
    end
  end

  describe "#create" do
    subject(:create) do
      subscriptions.create(
        type: "user.update",
        version: "1",
        condition: {user_id: "1234"},
        callback: "https://this-is-a-callback.com"
      )
    end

    before do
      stub_const("ENV", ENV.to_h.merge("TWITCH_EVENTSUB_SECRET" => "s3cret"))
      allow(client).to receive(:post_json) do |*_args, **_kwargs, &block|
        block.call(fixture("eventsub_subscription_created_documented_example"))
      end
    end

    it "posts a webhook subscription" do
      create

      expect(client).to have_received(:post_json).with(
        "/eventsub/subscriptions",
        body: {
          type: "user.update",
          version: "1",
          condition: {user_id: "1234"},
          transport: {method: "webhook", callback: "https://this-is-a-callback.com", secret: "s3cret"}
        }
      )
    end

    it "returns the created subscription" do
      expect(create).to eq(
        Integrations::Twitch::EventSubSubscription.new(
          id: "26b1c993-bfcf-44d9-b876-379dacafe75a",
          type: "user.update",
          version: "1",
          status: "webhook_callback_verification_pending",
          condition: {"user_id" => "1234"},
          callback: "https://this-is-a-callback.com"
        )
      )
    end
  end

  describe "#destroy" do
    subject(:destroy) { subscriptions.destroy("26b1c993") }

    before do
      allow(client).to receive(:delete).and_return(nil)
    end

    it "deletes the subscription by id" do
      destroy

      expect(client).to have_received(:delete).with("/eventsub/subscriptions", params: {id: "26b1c993"})
    end

    context "when Twitch already removed it" do
      before do
        allow(client).to receive(:delete).and_raise(Integrations::NotFound)
      end

      it "treats it as deleted" do
        expect(destroy).to be_nil
      end
    end
  end
end
