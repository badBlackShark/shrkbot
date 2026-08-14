# frozen_string_literal: true

require "rails_helper"

RSpec.describe PluginPaths do
  describe ".for" do
    subject(:path) { described_class.for(server_configuration, key) }

    context "with a real server configuration" do
      let(:server_configuration) { create(:server_configuration, discord_id: 900_000_001) }

      context "with a catalog plugin key" do
        let(:key) { :roles }

        it "builds the real config page path" do
          expect(path).to eq("/servers/900000001/roles")
        end
      end

      context "with a global plugin key" do
        let(:key) { :reminders }

        it "builds the real config page path" do
          expect(path).to eq("/servers/900000001/reminders")
        end
      end

      context "with a bespoke plugin key" do
        let(:key) { :twilight_struggle }

        it "builds the real config page path" do
          expect(path).to eq("/servers/900000001/twilight_struggle")
        end
      end

      context "with a key PluginCatalog does not recognize" do
        let(:key) { :nonsense }

        it "raises the unknown-key guard" do
          expect { path }.to raise_error(ArgumentError, /unknown plugin key/)
        end
      end
    end

    context "with a preview server configuration" do
      let(:server_configuration) { create(:server_configuration, :preview) }

      context "with a catalog plugin key" do
        let(:key) { :roles }

        it "builds the preview config page path" do
          expect(path).to eq("/preview/roles")
        end
      end

      context "with a global plugin key" do
        let(:key) { :reminders }

        it "builds the preview config page path" do
          expect(path).to eq("/preview/reminders")
        end
      end

      context "with a bespoke plugin key" do
        let(:key) { :twilight_struggle }

        it "raises, since there is no preview route for a bespoke plugin" do
          expect { path }.to raise_error(ArgumentError, /bespoke/)
        end
      end
    end
  end

  describe ".dashboard_for" do
    subject(:dashboard_path) { described_class.dashboard_for(discord_id) }

    context "with a real server discord id" do
      let(:discord_id) { 900_000_001 }

      it "builds the server dashboard path" do
        expect(dashboard_path).to eq("/servers/900000001")
      end
    end

    context "with a preview discord id" do
      let(:discord_id) { -1 }

      it "builds the preview dashboard path" do
        expect(dashboard_path).to eq("/preview")
      end
    end
  end
end
