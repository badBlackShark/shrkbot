# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Reminders::Settings::Update do
  subject(:result) do
    described_class.call(server_configuration: server, force_dm_reminders:)
  end

  let(:server) { create(:server_configuration, discord_id: 1) }
  let(:force_dm_reminders) { "1" }

  it "turns forced DM delivery on" do
    expect(result.success?).to be(true)
    expect(server.reload.force_dm_reminders).to be(true)
  end

  context "turning it back off" do
    before do
      server.update!(force_dm_reminders: true)
    end

    let(:force_dm_reminders) { "0" }

    it "clears the flag" do
      result
      expect(server.reload.force_dm_reminders).to be(false)
    end
  end
end
