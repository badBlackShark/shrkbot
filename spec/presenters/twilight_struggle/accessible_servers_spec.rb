# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::AccessibleServers do
  subject(:servers) { described_class.new(user:, manageable_discord_ids:).all }

  let(:user) { create(:user) }
  let(:granted_and_managed) { create(:server_configuration, name: "Mine") }
  let(:granted_elsewhere) { create(:server_configuration, name: "Someone else's") }
  let(:managed_without_grant) { create(:server_configuration, name: "No grant") }
  let(:manageable_discord_ids) { [granted_and_managed.discord_id, managed_without_grant.discord_id] }

  before do
    create(:bespoke_plugin_grant, server_configuration: granted_and_managed, plugin_key: "twilight_struggle")
    create(:bespoke_plugin_grant, server_configuration: granted_elsewhere, plugin_key: "twilight_struggle")
    managed_without_grant
  end

  it "includes a granted server the user manages" do
    expect(servers).to contain_exactly(granted_and_managed)
  end

  context "when the user is the bot owner" do
    before do
      allow(Bot::Config).to receive(:owner_id).and_return(user.discord_id.to_s)
    end

    it "includes every granted server, managed or not" do
      expect(servers).to contain_exactly(granted_and_managed, granted_elsewhere)
    end

    it "still excludes servers without a grant" do
      expect(servers).not_to include(managed_without_grant)
    end
  end

  context "when the grant is for a different plugin" do
    before do
      granted_and_managed.bespoke_plugin_grants.update_all(plugin_key: "something_else")
    end

    it "is empty" do
      expect(servers).to be_empty
    end
  end
end
