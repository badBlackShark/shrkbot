# frozen_string_literal: true

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
        expect(Ops::Roles::Messages::Repost).to receive(:call).with(bot:, role_set: set)
          .and_return(instance_double(Ops::ApplicationOperation::Result, success?: true))

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

    context "with a roles_post event for an existing set" do
      let(:set) { create(:role_set) }
      let(:payload) { JSON.generate(type: "roles_post", set_id: set.id) }

      it "runs the Post operation for that set with the bot" do
        expect(Ops::Roles::Messages::Post).to receive(:call).with(bot:, role_set: set)
          .and_return(instance_double(Ops::ApplicationOperation::Result, success?: true))
        subscriber.handle(payload)
      end
    end

    context "with a roles_post event for a missing set" do
      let(:payload) { JSON.generate(type: "roles_post", set_id: "rls_missing") }

      it "does not run the Post operation" do
        expect(Ops::Roles::Messages::Post).not_to receive(:call)
        subscriber.handle(payload)
      end
    end

    context "with a roles_message_delete event" do
      let(:payload) { JSON.generate(type: "roles_message_delete", channel_id: 111, message_id: 222) }

      it "runs the Delete operation with the raw ids" do
        expect(Ops::Roles::Messages::Delete).to receive(:call).with(bot:, channel_id: 111, message_id: 222)
          .and_return(instance_double(Ops::ApplicationOperation::Result, success?: true))
        subscriber.handle(payload)
      end
    end

    context "with a roles_menu_remove event for an existing set" do
      let(:set) { create(:role_set, message_id: 999) }
      let(:payload) { JSON.generate(type: "roles_menu_remove", set_id: set.id) }

      it "runs the Remove operation for that set with the bot" do
        expect(Ops::Roles::Messages::Remove).to receive(:call).with(bot:, role_set: set)
          .and_return(instance_double(Ops::ApplicationOperation::Result, success?: true))

        subscriber.handle(payload)
      end
    end

    context "with a roles_menu_remove event for a missing set" do
      let(:payload) { JSON.generate(type: "roles_menu_remove", set_id: "rls_missing") }

      it "does not run the Remove operation" do
        expect(Ops::Roles::Messages::Remove).not_to receive(:call)
        subscriber.handle(payload)
      end
    end

    context "when a Remove operation returns a failure Result" do
      let(:set) { create(:role_set, message_id: 999) }
      let(:payload) { JSON.generate(type: "roles_menu_remove", set_id: set.id) }
      let(:failure_result) do
        instance_double(Ops::ApplicationOperation::Result, success?: false, errors: ["channel not found"])
      end

      before do
        allow(Ops::Roles::Messages::Remove).to receive(:call).and_return(failure_result)
        allow(Rails.logger).to receive(:error)
      end

      it "logs the failure" do
        subscriber.handle(payload)
        expect(Rails.logger).to have_received(:error).with(a_string_including("roles_menu_remove failed"))
      end
    end

    context "when a Post operation returns a failure Result" do
      let(:set) { create(:role_set) }
      let(:payload) { JSON.generate(type: "roles_post", set_id: set.id) }
      let(:failure_result) do
        instance_double(Ops::ApplicationOperation::Result, success?: false, errors: ["channel not found"])
      end

      before do
        allow(Ops::Roles::Messages::Post).to receive(:call).and_return(failure_result)
        allow(Rails.logger).to receive(:error)
      end

      it "logs the failure" do
        subscriber.handle(payload)
        expect(Rails.logger).to have_received(:error).with(a_string_including("roles_post failed"))
      end
    end
  end
end
