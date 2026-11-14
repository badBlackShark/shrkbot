# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::SubPluginContext do
  let(:config) { create(:server_configuration, discord_id: 900_000_001) }

  before do
    config.create_moderation_settings!
    config.create_spam_protection_settings!
    config.create_image_scanning_settings!
  end

  describe "#settings" do
    context "when plugin_key is :spam_protection" do
      subject(:ctx) { described_class.new(config, :spam_protection) }

      it "returns the spam_protection_settings" do
        expect(ctx.settings).to eq(config.spam_protection_settings)
      end
    end

    context "when plugin_key is :image_scanning" do
      subject(:ctx) { described_class.new(config, :image_scanning) }

      it "returns the image_scanning_settings" do
        expect(ctx.settings).to eq(config.image_scanning_settings)
      end
    end
  end
end
