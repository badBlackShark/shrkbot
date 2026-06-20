require "rails_helper"

RSpec.describe ConfigSubscriber do
  subject(:subscriber) { described_class.new(bot) }

  let(:bot) { double("bot") }

  describe "#start" do
    let(:redis) { double("redis") }
    let(:on) { double("on") }

    it "subscribes on the config channel and routes each message to #handle" do
      allow(Thread).to receive(:new).and_yield
      allow(Redis).to receive(:new).with(url: BotConfig.redis_url).and_return(redis)
      allow(redis).to receive(:subscribe).with(ConfigBus::CHANNEL).and_yield(on)
      allow(on).to receive(:message).and_yield("shrkbot:config", "payload")

      expect(subscriber).to receive(:handle).with("payload")

      subscriber.start
    end
  end

  describe "#handle" do
    context "with a roles_repost event for an existing set" do
      let(:set) { create(:role_set) }
      let(:payload) { JSON.generate(type: "roles_repost", set_id: set.id) }

      it "runs the repost operation for that set with the bot" do
        expect(Ops::Roles::Messages::Repost).to receive(:call).with(bot: bot, role_set: set)

        subscriber.handle(payload)
      end
    end

    context "when the set no longer exists" do
      let(:payload) { JSON.generate(type: "roles_repost", set_id: "rls_missing") }

      it "does not run the operation" do
        expect(Ops::Roles::Messages::Repost).not_to receive(:call)
        subscriber.handle(payload)
      end
    end

    context "with an unknown event type" do
      let(:payload) { JSON.generate(type: "something_else", set_id: "x") }

      it "ignores it without raising" do
        expect { subscriber.handle(payload) }.not_to raise_error
      end
    end

    context "with malformed JSON" do
      let(:payload) { "not json" }

      it "reports the error instead of crashing the listener" do
        allow(OwnerNotifier).to receive(:report)
        expect { subscriber.handle(payload) }.not_to raise_error
        expect(OwnerNotifier).to have_received(:report)
      end
    end
  end
end
