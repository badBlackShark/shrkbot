# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::MemberJoin do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 123, member_count: 10) }
  let(:user) { double("user", mention: "<@7>", id: 7, username: "newmember", display_name: "New Member", pending: false) }
  let(:bot) { double("bot", send_message: nil) }
  let(:event) { double("event", server:, user:, bot:) }
  let(:pending_joins) { Welcomes::PendingJoins.new }
  let(:setting) { double("settings", channel_id: 555, join_message: "Welcome {user}!", ping_on_join: true) }

  before do
    allow(Welcomes::PendingJoins).to receive(:instance).and_return(pending_joins)
    allow(Welcomes::Settings).to receive(:active_for).with(123).and_return(setting)
  end

  context "when the member is already through onboarding" do
    it "welcomes them straight away" do
      handle

      expect(bot).to have_received(:send_message).with(555, "Welcome <@7>!", false, nil, nil, nil, nil, nil, 0)
    end

    it "holds nothing back" do
      handle

      expect(pending_joins.forget(guild_id: 123, user_id: 7)).to be(false)
    end
  end

  context "when the member still has onboarding to finish" do
    let(:user) { double("user", mention: "<@7>", id: 7, username: "newmember", display_name: "New Member", pending: true) }

    it "holds the welcome back so the mention resolves later" do
      handle

      expect(bot).not_to have_received(:send_message)
    end

    it "remembers the join so finishing onboarding can trigger it" do
      handle

      expect(pending_joins.forget(guild_id: 123, user_id: 7)).to be(true)
    end
  end

  context "when welcomes is inactive" do
    let(:setting) { nil }
    let(:user) { double("user", mention: "<@7>", id: 7, username: "newmember", display_name: "New Member", pending: true) }

    it "remembers nothing, since no welcome will ever be sent" do
      handle

      expect(pending_joins.forget(guild_id: 123, user_id: 7)).to be(false)
    end
  end
end
