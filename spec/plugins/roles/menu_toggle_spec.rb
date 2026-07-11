# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::MenuToggle do
  subject(:publish) { described_class.publish(server_configuration, enabled:) }

  let(:server_configuration) { create(:server_configuration) }
  let!(:role_setting) { create(:role_setting, server_configuration:) }

  before do
    allow(Bot::ConfigBus).to receive(:post_roles)
    allow(Bot::ConfigBus).to receive(:remove_roles_menu)
    allow(Bot::ConfigBus).to receive(:delete_roles_message)
  end

  context "when enabling with two sets (one with message_id, one without)" do
    let(:enabled) { true }
    let!(:set_with_message) { create(:role_set, role_setting:, message_id: 111) }
    let!(:set_without_message) { create(:role_set, role_setting:) }

    it "publishes post_roles for both sets" do
      publish
      expect(Bot::ConfigBus).to have_received(:post_roles).with(set_with_message)
      expect(Bot::ConfigBus).to have_received(:post_roles).with(set_without_message)
    end

    it "does not publish remove_roles_menu" do
      publish
      expect(Bot::ConfigBus).not_to have_received(:remove_roles_menu)
    end
  end

  context "when disabling with two sets (one with message_id, one without)" do
    let(:enabled) { false }
    let!(:set_with_message) { create(:role_set, role_setting:, message_id: 111) }
    let!(:set_without_message) { create(:role_set, role_setting:) }

    it "publishes remove_roles_menu only for the set with a message" do
      publish
      expect(Bot::ConfigBus).to have_received(:remove_roles_menu).with(set_with_message)
      expect(Bot::ConfigBus).not_to have_received(:remove_roles_menu).with(set_without_message)
    end

    it "does not publish post_roles" do
      publish
      expect(Bot::ConfigBus).not_to have_received(:post_roles)
    end
  end

  context "when enabling with no sets" do
    let(:enabled) { true }

    it "publishes neither post_roles nor remove_roles_menu" do
      publish
      expect(Bot::ConfigBus).not_to have_received(:post_roles)
      expect(Bot::ConfigBus).not_to have_received(:remove_roles_menu)
    end
  end
end
