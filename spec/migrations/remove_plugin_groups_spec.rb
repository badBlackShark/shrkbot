# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261114122427_remove_plugin_groups")

RSpec.describe RemovePluginGroups, skip_prosopite: true do
  subject(:migrate) do
    ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) }
  end

  let(:server) { create(:server_configuration) }

  def activate(key, enabled:, server: self.server)
    create(:plugin_activation, server_configuration: server, plugin: create(:plugin, key:)).tap do |activation|
      activation.update_column(:enabled, enabled)
    end
  end

  context "when Server Shield was off" do
    let!(:moderation) { activate("moderation", enabled: false) }
    let!(:protection) { activate("spam_protection", enabled: true) }

    it "turns its protection off" do
      migrate

      expect(protection.reload.enabled).to be(false)
    end
  end

  context "when Server Shield was on" do
    let!(:moderation) { activate("moderation", enabled: true) }
    let!(:protection) { activate("spam_protection", enabled: true) }

    it "keeps its protection on" do
      migrate

      expect(protection.reload.enabled).to be(true)
    end
  end

  context "when the server had no Server Shield row" do
    let!(:protection) { activate("image_scanning", enabled: true) }

    it "turns its protection off" do
      migrate

      expect(protection.reload.enabled).to be(false)
    end
  end

  context "when Integrations was off" do
    let!(:integrations) { activate("integrations", enabled: false) }
    let!(:steam) { activate("steam", enabled: true) }

    it "turns Steam off" do
      migrate

      expect(steam.reload.enabled).to be(false)
    end
  end

  context "when another server had the group on" do
    let(:other_server) { create(:server_configuration) }
    let!(:moderation) { activate("moderation", enabled: false) }
    let!(:protection) { activate("spam_protection", enabled: true) }
    let!(:other_moderation) { activate("moderation", enabled: true, server: other_server) }
    let!(:other_protection) { activate("spam_protection", enabled: true, server: other_server) }

    it "keeps that server's protection on" do
      migrate

      expect(other_protection.reload.enabled).to be(true)
    end
  end

  context "with group rows present" do
    let!(:moderation) { activate("moderation", enabled: true) }
    let!(:integrations) { activate("integrations", enabled: true) }

    it "deletes the group activations and plugins" do
      migrate

      expect(Plugin.where(key: %w[moderation integrations])).to be_empty
      expect(PluginActivation.where(id: [moderation.id, integrations.id])).to be_empty
    end
  end

  context "with an unrelated plugin" do
    let!(:logging) { activate("logging", enabled: true) }

    it "leaves it untouched" do
      migrate

      expect(logging.reload.enabled).to be(true)
    end
  end
end
