# frozen_string_literal: true

require "rails_helper"

RSpec.describe PluginAccess do
  include_context "with a bespoke plugin definition"

  subject(:access) do
    described_class.new(user:, server_configuration:, manages_server:)
  end

  let(:user) { create(:user) }
  let(:server_configuration) { create(:server_configuration) }
  let(:manages_server) { true }

  describe "#manage?" do
    context "when the user manages the server" do
      it "is true for a normal plugin key" do
        expect(access.manage?(:roles)).to be(true)
      end

      it "is true for the global reminders key" do
        expect(access.manage?(:reminders)).to be(true)
      end

      it "is false for a bespoke key without a grant" do
        expect(access.manage?(:bespoke_thing)).to be(false)
      end

      context "when the server holds the bespoke grant" do
        before { create(:bespoke_plugin_grant, server_configuration:, plugin_key: bespoke_definition.key) }

        it "is true for the granted bespoke key" do
          expect(access.manage?(:bespoke_thing)).to be(true)
        end
      end
    end

    context "when the user does not manage the server" do
      let(:manages_server) { false }

      it "is false for a normal plugin key" do
        expect(access.manage?(:roles)).to be(false)
      end

      context "when the user is a tournament organiser" do
        let(:tournament) { create(:twilight_struggle_tournament) }
        let(:plugin) { create(:plugin, key: "twilight_struggle", name: "Twilight Struggle") }

        before { create(:twilight_struggle_tournament_admin, tournament:, discord_id: user.discord_id) }

        context "when the server holds the grant and the plugin is enabled" do
          before do
            create(:bespoke_plugin_grant, server_configuration:, plugin_key: "twilight_struggle")
            create(:plugin_activation, server_configuration:, plugin:, enabled: true)
          end

          it "is true for the twilight_struggle key" do
            expect(access.manage?(:twilight_struggle)).to be(true)
          end

          it "is false for an unrelated plugin key" do
            expect(access.manage?(:roles)).to be(false)
          end
        end

        context "when the server does not hold the twilight_struggle bespoke grant" do
          it "is false for the twilight_struggle key" do
            expect(access.manage?(:twilight_struggle)).to be(false)
          end
        end

        context "when the grant is present but the plugin is not enabled" do
          before { create(:bespoke_plugin_grant, server_configuration:, plugin_key: "twilight_struggle") }

          it "is false for the twilight_struggle key" do
            expect(access.manage?(:twilight_struggle)).to be(false)
          end
        end
      end

      context "when the grant is present and the plugin enabled but the user has no tournament admin row" do
        let(:plugin) { create(:plugin, key: "twilight_struggle", name: "Twilight Struggle") }

        before do
          create(:bespoke_plugin_grant, server_configuration:, plugin_key: "twilight_struggle")
          create(:plugin_activation, server_configuration:, plugin:, enabled: true)
        end

        it "is false for the twilight_struggle key" do
          expect(access.manage?(:twilight_struggle)).to be(false)
        end
      end
    end
  end

  describe "#visible?" do
    context "when the user manages the server" do
      it "is true for a normal plugin key" do
        expect(access.visible?(:roles)).to be(true)
      end

      it "is false for an ungranted bespoke key" do
        expect(access.visible?(:bespoke_thing)).to be(false)
      end
    end

    context "when the user does not manage the server" do
      let(:manages_server) { false }

      it "is still true for a normal plugin key" do
        expect(access.visible?(:roles)).to be(true)
      end

      it "is false for an ungranted bespoke key" do
        expect(access.visible?(:bespoke_thing)).to be(false)
      end
    end
  end

  describe "#toggle?" do
    context "when the user manages the server" do
      it "is true for a key they manage" do
        expect(access.toggle?(:roles)).to be(true)
      end

      it "is false for a bespoke key without a grant" do
        expect(access.toggle?(:bespoke_thing)).to be(false)
      end
    end

    context "when the user is an organiser but does not manage the server" do
      let(:manages_server) { false }
      let(:tournament) { create(:twilight_struggle_tournament) }
      let(:plugin) { create(:plugin, key: "twilight_struggle", name: "Twilight Struggle") }

      before do
        create(:twilight_struggle_tournament_admin, tournament:, discord_id: user.discord_id)
        create(:bespoke_plugin_grant, server_configuration:, plugin_key: "twilight_struggle")
        create(:plugin_activation, server_configuration:, plugin:, enabled: true)
      end

      it "is false for the twilight_struggle key even though manage? is true" do
        expect(access.manage?(:twilight_struggle)).to be(true)
        expect(access.toggle?(:twilight_struggle)).to be(false)
      end
    end
  end
end
