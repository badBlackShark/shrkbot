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
    it "lets the configured owner run anything, including owner_only commands" do
      allow(BotConfig).to receive(:owner_id).and_return("42")
      event = event_for(user_id: 42)
      expect(described_class.permitted?(event:, required: [:manage_server], owner_only: true)).to be(true)
    end

    it "rejects owner_only commands for non-owners" do
      allow(BotConfig).to receive(:owner_id).and_return("42")
      event = event_for(user_id: 7, member: double(permission?: true))
      expect(described_class.permitted?(event:, required: [], owner_only: true)).to be(false)
    end

    it "allows commands with no required permissions" do
      allow(BotConfig).to receive(:owner_id).and_return(nil)
      event = event_for(user_id: 7, member: double(permission?: false))
      expect(described_class.permitted?(event:, required: [], owner_only: false)).to be(true)
    end

    it "requires the member to hold every declared permission" do
      allow(BotConfig).to receive(:owner_id).and_return(nil)
      member = double("member")
      allow(member).to receive(:permission?).with(:manage_server).and_return(true)
      allow(member).to receive(:permission?).with(:ban_members).and_return(false)
      event = event_for(user_id: 7, member:)

      expect(described_class.permitted?(event:, required: %i[manage_server ban_members], owner_only: false)).to be(false)
    end

    it "grants when the member holds the single required permission" do
      allow(BotConfig).to receive(:owner_id).and_return(nil)
      member = double("member")
      allow(member).to receive(:permission?).with(:manage_server).and_return(true)
      event = event_for(user_id: 7, member:)

      expect(described_class.permitted?(event:, required: [:manage_server], owner_only: false)).to be(true)
    end

    it "denies a permission-gated command in a DM (no member to check)" do
      allow(BotConfig).to receive(:owner_id).and_return(nil)
      event = event_for(user_id: 7) # no member
      expect(described_class.permitted?(event:, required: [:manage_server], owner_only: false)).to be(false)
    end
  end
end
