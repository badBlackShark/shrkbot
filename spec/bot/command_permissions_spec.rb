require "rails_helper"

RSpec.describe CommandPermissions do
  def event_for(user_id:, member: :unset)
    user = double("user", id: user_id)
    if member == :unset
      double("event", user: user) # DM-style: no member
    else
      double("event", user: user, member: member)
    end
  end

  describe ".permitted?" do
    subject(:permitted) { described_class.permitted?(event:, required:, owner_only:) }

    context "when the user is the configured owner" do
      before do
        allow(BotConfig).to receive(:owner_id).and_return("42")
      end

      let(:event) { event_for(user_id: 42) }

      context "requesting owner_only" do
        let(:required) { [:manage_server] }
        let(:owner_only) { true }

        it "grants access" do
          is_expected.to be(true)
        end
      end
    end

    context "when the user is not the configured owner and owner_only is true" do
      before do
        allow(BotConfig).to receive(:owner_id).and_return("42")
      end

      let(:event) { event_for(user_id: 7, member: double(permission?: true)) }
      let(:required) { [] }
      let(:owner_only) { true }

      it "denies access" do
        is_expected.to be(false)
      end
    end

    context "when no owner is configured and command requires no permissions" do
      before do
        allow(BotConfig).to receive(:owner_id).and_return(nil)
      end

      let(:event) { event_for(user_id: 7, member: double(permission?: false)) }
      let(:required) { [] }
      let(:owner_only) { false }

      it "grants access" do
        is_expected.to be(true)
      end
    end

    context "when multiple permissions are required and member lacks one" do
      before do
        allow(BotConfig).to receive(:owner_id).and_return(nil)
      end

      let(:member) do
        double("member").tap do |m|
          allow(m).to receive(:permission?).with(:manage_server).and_return(true)
          allow(m).to receive(:permission?).with(:ban_members).and_return(false)
        end
      end

      let(:event) { event_for(user_id: 7, member:) }
      let(:required) { %i[manage_server ban_members] }
      let(:owner_only) { false }

      it "denies access" do
        is_expected.to be(false)
      end
    end

    context "when a single required permission is held" do
      before do
        allow(BotConfig).to receive(:owner_id).and_return(nil)
      end

      let(:member) do
        double("member").tap do |m|
          allow(m).to receive(:permission?).with(:manage_server).and_return(true)
        end
      end

      let(:event) { event_for(user_id: 7, member:) }
      let(:required) { [:manage_server] }
      let(:owner_only) { false }

      it "grants access" do
        is_expected.to be(true)
      end
    end

    context "when a permission-gated command is used in a DM (no member)" do
      before do
        allow(BotConfig).to receive(:owner_id).and_return(nil)
      end

      let(:event) { event_for(user_id: 7) }
      let(:required) { [:manage_server] }
      let(:owner_only) { false }

      it "denies access" do
        is_expected.to be(false)
      end
    end
  end
end
