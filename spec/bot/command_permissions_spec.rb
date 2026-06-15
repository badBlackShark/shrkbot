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
      event = event_for(user_id: 42)
      expect(described_class.permitted?(event:, required: [:manage_server], owner_only: true, owner_id: "42")).to be(true)
    end

    it "rejects owner_only commands for non-owners" do
      event = event_for(user_id: 7, member: double(permission?: true))
      expect(described_class.permitted?(event:, required: [], owner_only: true, owner_id: "42")).to be(false)
    end

    it "allows commands with no required permissions" do
      event = event_for(user_id: 7, member: double(permission?: false))
      expect(described_class.permitted?(event:, required: [], owner_only: false, owner_id: nil)).to be(true)
    end

    it "requires the member to hold every declared permission" do
      member = double("member")
      allow(member).to receive(:permission?).with(:manage_server).and_return(true)
      allow(member).to receive(:permission?).with(:ban_members).and_return(false)
      event = event_for(user_id: 7, member:)

      expect(described_class.permitted?(event:, required: %i[manage_server ban_members], owner_only: false, owner_id: nil)).to be(false)
    end

    it "grants when the member holds the single required permission" do
      member = double("member")
      allow(member).to receive(:permission?).with(:manage_server).and_return(true)
      event = event_for(user_id: 7, member:)

      expect(described_class.permitted?(event:, required: [:manage_server], owner_only: false, owner_id: nil)).to be(true)
    end

    it "denies a permission-gated command in a DM (no member to check)" do
      event = event_for(user_id: 7) # no member
      expect(described_class.permitted?(event:, required: [:manage_server], owner_only: false, owner_id: nil)).to be(false)
    end
  end
end
