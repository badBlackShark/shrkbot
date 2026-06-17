require "rails_helper"

RSpec.describe BaseCommand do
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
  end

  describe "#dispatch template" do
    let(:event) { double("event", user: double(id: 1), member: double(permission?: true), respond: nil, bot: double("bot")) }

    def command_class(&body)
      Class.new(described_class) do
        command_name :probe
        define_method(:execute, &body)
      end
    end

    before { allow(BotConfig).to receive(:owner_id).and_return(nil) }

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

    context "when not permitted" do
      subject(:dispatch) { klass.dispatch(denied_event) }

      let(:klass) do
        Class.new(described_class) do
          command_name :probe
          requires_permissions :manage_server

          def execute
            raise "should not run"
          end
        end
      end

      let(:denied_event) do
        double("event", user: double(id: 1), member: double, respond: nil).tap do |e|
          allow(e.member).to receive(:permission?).with(:manage_server).and_return(false)
        end
      end

      it "replies with a denial and skips #execute" do
        expect(denied_event).to receive(:respond).with(hash_including(content: a_string_including("permission"), ephemeral: true))
        dispatch
      end
    end

    context "when #execute raises" do
      subject(:dispatch) { klass.dispatch(event) }

      let(:klass) { command_class { raise "boom" } }

      it "reports to the owner and responds without raising" do
        expect(OwnerNotifier).to receive(:report).with(hash_including(source: "command /probe"))
        expect(event).to receive(:respond).with(hash_including(ephemeral: true))
        expect { dispatch }.not_to raise_error
      end
    end
  end
end
