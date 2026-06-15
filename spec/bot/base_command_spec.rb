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

    it "builds a registration descriptor from the macros" do
      reg = klass.registration
      expect(reg.name).to eq(:remind)
      expect(reg.description).to eq("Set a reminder.")
      expect(reg.permissions).to eq(%i[manage_server ban_members])
      expect(reg.global?).to be(true)
      expect(reg.contexts).to eq(%i[server bot_dm])
      expect(reg.options_block).to be_a(Proc)
    end

    it "defaults to :guild context (no DM) with empty permissions" do
      plain = Class.new(described_class) { command_name :info }
      reg = plain.registration
      expect(reg.global?).to be(false)
      expect(reg.contexts).to be_nil
      expect(reg.permissions).to eq([])
    end

    it "treats only named subclasses as registrable" do
      expect(klass.registrable).to be(true)
      expect(Class.new(described_class).registrable).to be(false)
    end
  end

  describe "#call template" do
    let(:event) { double("event", user: double(id: 1), member: double(permission?: true), respond: nil) }

    def command_class(&body)
      Class.new(described_class) do
        command_name :probe
        define_method(:execute, &body)
      end
    end

    before { allow(BotConfig).to receive(:owner_id).and_return(nil) }

    it "runs #execute when permitted" do
      ran = false
      klass = command_class { ran = true }
      klass.dispatch(event)
      expect(ran).to be(true)
    end

    it "replies with a denial and skips #execute when not permitted" do
      klass = Class.new(described_class) do
        command_name :probe
        requires_permissions :manage_server
        def execute = raise("should not run")
      end
      denied_event = double("event", user: double(id: 1), member: double, respond: nil)
      allow(denied_event.member).to receive(:permission?).with(:manage_server).and_return(false)

      expect(denied_event).to receive(:respond).with(hash_including(content: a_string_including("permission"), ephemeral: true))
      klass.dispatch(denied_event)
    end

    it "rescues errors in #execute and responds without raising" do
      klass = command_class { raise "boom" }
      expect(event).to receive(:respond).with(hash_including(ephemeral: true))
      expect { klass.dispatch(event) }.not_to raise_error
    end
  end
end
