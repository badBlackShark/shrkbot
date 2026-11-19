# frozen_string_literal: true

RSpec.shared_context "moderation button event" do
  subject(:handle) { described_class.new(event).handle }

  let(:guild_id) { 111 }
  let(:staff_role_id) { 333 }
  let(:actor_id) { 222 }
  let(:staff_role) { double("role", id: staff_role_id) }
  let(:member) { double("member", mention: "<@#{actor_id}>", roles: [staff_role], permission?: false) }
  let(:server) { double("server", id: guild_id, name: "Test Server") }
  let(:user) { double("user", id: actor_id) }
  let(:bot) { double("bot") }
  let(:fake_container) { double("container", components: [], buttons: []) }
  let(:fake_message) { double("message", components: [fake_container]) }
  let(:event) do
    double(
      "event",
      custom_id:,
      server:,
      user:,
      update_message: nil,
      respond: nil,
      defer: nil,
      edit_response: nil,
      bot:,
      message: fake_message
    )
  end

  let!(:config) { create(:server_configuration, discord_id: guild_id) }
  let!(:settings) { create(:moderation_settings, server_configuration: config, staff_role_id:) }

  before do
    allow(server).to receive(:member).with(actor_id).and_return(member)
  end
end
