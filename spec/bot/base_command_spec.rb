# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::BaseCommand do
  describe "declaration macros + .registration" do
    let(:klass) do
      Class.new(described_class) do
        command_name :remind
        description "Set a reminder."
        requires_permissions :manage_server, :ban_members
        register_in :global
        options { |b| b.string("text", "what to remind") }
      end
    end

    subject(:registration) { klass.registration }

    it "builds a registration descriptor from the macros" do
      expect(registration.name).to eq(:remind)
      expect(registration.description).to eq("Set a reminder.")
      expect(registration.permissions).to eq(%i[manage_server ban_members])
      expect(registration.global?).to be(true)
      expect(registration.contexts).to eq(%i[server bot_dm])
      expect(registration.options_block).to be_a(Proc)
    end

    context "plain command without explicit settings" do
      let(:klass) { Class.new(described_class) { command_name :info } }

      it "defaults to :guild context (no DM) with empty permissions" do
        expect(registration.global?).to be(false)
        expect(registration.contexts).to be_nil
        expect(registration.permissions).to eq([])
      end
    end

    context "registrable detection" do
      it "treats only named subclasses as registrable" do
        expect(klass.registrable).to be(true)
      end

      it "treats anonymous subclasses as non-registrable" do
        anonymous = Class.new(described_class)
        expect(anonymous.registrable).to be(false)
      end
    end

    context "chat_input commands (default)" do
      it "carry their description, options, and a :chat_input type" do
        expect(registration.type).to eq(:chat_input)
        expect(registration.description).to eq("Set a reminder.")
        expect(registration.options_block).to be_a(Proc)
      end
    end

    context "context-menu commands" do
      let(:klass) do
        Class.new(described_class) do
          command_name "Report as scam"
          description "ignored"
          command_type :message
          options { |b| b.string("x", "y") }
        end
      end

      it "register as :message with an empty description and no options" do
        expect(registration.type).to eq(:message)
        expect(registration.name).to eq("Report as scam")
        expect(registration.description).to eq("")
        expect(registration.options_block).to be_nil
      end
    end

    context "owner-only commands" do
      let(:klass) do
        Class.new(described_class) do
          command_name :secret
          owner_only
        end
      end

      it "carries the flag through to the registration" do
        expect(klass.owner_only?).to be(true)
        expect(klass.registration.owner_only).to be(true)
      end
    end
  end

  describe "#execute" do
    it "is abstract" do
      klass = Class.new(described_class) { command_name :probe }
      expect { klass.new(double("event")).execute }.to raise_error(AbstractMethodError)
    end
  end

  describe "#dispatch template" do
    let(:event) { double("event", user: double(id: 1), respond: nil, bot: double("bot")) }

    def command_class(&body)
      Class.new(described_class) do
        command_name :probe
        define_method(:execute, &body)
      end
    end

    before do
      allow(Bot::Config).to receive(:owner_id).and_return(nil)
    end

    context "when permitted" do
      subject(:dispatch) { klass.dispatch(event) }

      let(:executed) { double("execute spy") }
      let(:klass) do
        spy = executed
        command_class { spy.run }
      end

      it "runs #execute" do
        expect(executed).to receive(:run)
        dispatch
      end
    end

    context "when not permitted (owner_only command, non-owner user)" do
      subject(:dispatch) { klass.dispatch(denied_event) }

      before do
        allow(Bot::Config).to receive(:owner_id).and_return("99")
      end

      let(:klass) do
        Class.new(described_class) do
          command_name :probe
          owner_only

          def execute
            raise "should not run"
          end
        end
      end

      let(:denied_event) do
        double("event", user: double(id: 1), respond: nil)
      end

      it "replies with a denial and skips #execute" do
        expect(denied_event).to receive(:respond).with(hash_including(content: a_string_including("permission"), ephemeral: true))
        dispatch
      end
    end

    context "when the invoker lacks a declared permission" do
      subject(:dispatch) { klass.dispatch(denied_event) }

      let(:klass) do
        Class.new(described_class) do
          command_name :probe
          requires_permissions :manage_messages

          def execute
            raise "should not run"
          end
        end
      end

      let(:user) { double("user", id: 1, permission?: false) }
      let(:denied_event) { double("event", user:, respond: nil) }

      it "replies with a denial and skips #execute" do
        expect(denied_event).to receive(:respond).with(hash_including(content: a_string_including("permission"), ephemeral: true))
        dispatch
      end
    end

    context "when #execute raises" do
      subject(:dispatch) { klass.dispatch(event) }

      let(:klass) { command_class { raise "boom" } }

      it "reports to the owner and responds without raising" do
        expect(Bot::OwnerNotifier).to receive(:report).with(hash_including(source: "command /probe"))
        expect(event).to receive(:respond).with(hash_including(ephemeral: true))
        expect { dispatch }.not_to raise_error
      end
    end

    context "when the error reply itself fails (interaction expired)" do
      subject(:dispatch) { klass.dispatch(event) }

      let(:klass) { command_class { raise "boom" } }

      it "swallows the secondary failure" do
        allow(Bot::OwnerNotifier).to receive(:report)
        allow(event).to receive(:respond).and_raise("interaction expired")
        expect { dispatch }.not_to raise_error
      end
    end
  end

  describe "autocomplete dispatch" do
    let(:event) { double("event", respond: nil, bot: double("bot")) }

    context "when the command defines #autocomplete" do
      let(:klass) do
        Class.new(described_class) do
          command_name :probe

          def autocomplete
            event.respond(choices: [{name: "a", value: "a"}])
          end
        end
      end

      it "runs it via .dispatch_autocomplete" do
        expect(event).to receive(:respond).with(choices: [{name: "a", value: "a"}])
        klass.dispatch_autocomplete(event)
      end
    end

    context "when #autocomplete raises" do
      let(:klass) do
        Class.new(described_class) do
          command_name :probe

          def autocomplete
            raise "boom"
          end
        end
      end

      it "clears the picker with empty choices instead of leaving it hanging" do
        expect(event).to receive(:respond).with(choices: [])
        expect { klass.dispatch_autocomplete(event) }.not_to raise_error
      end

      it "swallows a secondary failure while clearing the picker" do
        allow(event).to receive(:respond).and_raise("interaction expired")
        expect { klass.dispatch_autocomplete(event) }.not_to raise_error
      end
    end
  end
end
