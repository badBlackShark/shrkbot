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

      context "when the user is a tournament admin of a tournament the server subscribes to" do
        let(:tournament) { create(:twilight_struggle_tournament) }

        before do
          create(:twilight_struggle_tournament_admin, tournament:, discord_id: user.discord_id)
          create(:twilight_struggle_destination, tournament:, server_configuration:, active: true)
        end

        context "when the server holds the twilight_struggle bespoke grant" do
          before { create(:bespoke_plugin_grant, server_configuration:, plugin_key: "twilight_struggle") }

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
      end

      context "when the grant is present but the user has no tournament admin row" do
        before { create(:bespoke_plugin_grant, server_configuration:, plugin_key: "twilight_struggle") }

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
end
