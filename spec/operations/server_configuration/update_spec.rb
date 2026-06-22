require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Update do
  subject(:result) { described_class.call(server_configuration: server, force_dm_reminders:) }

  let(:server) { create(:server_configuration, discord_id: 1, force_dm_reminders: false) }

  context "enabling forced DM delivery" do
    let(:force_dm_reminders) { true }

    it "persists the flag" do
      expect(result.success?).to be(true)
      expect(server.reload.force_dm_reminders).to be(true)
    end
  end

  context "disabling forced DM delivery" do
    let(:server) { create(:server_configuration, discord_id: 1, force_dm_reminders: true) }
    let(:force_dm_reminders) { false }

    it "persists the flag" do
      expect(result.success?).to be(true)
      expect(server.reload.force_dm_reminders).to be(false)
    end
  end
end
