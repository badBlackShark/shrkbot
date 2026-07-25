# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::EffectiveConfig do
  subject(:config) { described_class.new(tournament) }

  let(:server_configuration) { create(:server_configuration) }

  describe "#channel_id and #server_configuration" do
    context "when the tournament has its own channel" do
      let(:tournament) do
        create(
          :twilight_struggle_tournament,
          discord_channel_id: 111,
          server_configuration:
        )
      end

      it "resolves its own channel id" do
        expect(config.channel_id).to eq(111)
      end

      it "resolves its own server configuration" do
        expect(config.server_configuration).to eq(server_configuration)
      end
    end

    context "when a child has no channel of its own" do
      let(:parent) do
        create(
          :twilight_struggle_tournament,
          discord_channel_id: 222,
          server_configuration:
        )
      end
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      it "inherits the parent's channel id" do
        expect(config.channel_id).to eq(222)
      end

      it "inherits the parent's server configuration" do
        expect(config.server_configuration).to eq(server_configuration)
      end
    end

    context "when the child sets its own server configuration but no channel" do
      let(:parent) do
        create(
          :twilight_struggle_tournament,
          discord_channel_id: 222,
          server_configuration:
        )
      end
      let(:own_server_configuration) { create(:server_configuration) }
      let(:tournament) do
        create(
          :twilight_struggle_tournament,
          parent:,
          server_configuration: own_server_configuration
        )
      end

      it "resolves the channel and server configuration as a pair from the parent, not mixed" do
        expect(config.channel_id).to eq(222)
        expect(config.server_configuration).to eq(server_configuration)
      end
    end

    context "when a grandchild has no channel and the parent sets nothing" do
      let(:grandparent) do
        create(
          :twilight_struggle_tournament,
          discord_channel_id: 333,
          server_configuration:
        )
      end
      let(:parent) { create(:twilight_struggle_tournament, parent: grandparent) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      it "inherits the grandparent's channel id" do
        expect(config.channel_id).to eq(333)
      end

      it "inherits the grandparent's server configuration" do
        expect(config.server_configuration).to eq(server_configuration)
      end
    end

    context "when nothing in the chain has a channel" do
      let(:parent) { create(:twilight_struggle_tournament) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      it "returns nil for channel id" do
        expect(config.channel_id).to be_nil
      end

      it "returns nil for server configuration" do
        expect(config.server_configuration).to be_nil
      end
    end
  end

  describe "#template_win" do
    context "when the tournament has its own template" do
      let(:tournament) { create(:twilight_struggle_tournament, template_win: "own template") }

      it "returns its own template" do
        expect(config.template_win).to eq("own template")
      end
    end

    context "when the tournament has none but the parent does" do
      let(:parent) { create(:twilight_struggle_tournament, template_win: "parent template") }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      it "inherits the parent's template" do
        expect(config.template_win).to eq("parent template")
      end
    end

    context "when the tournament's own template is blank" do
      let(:parent) { create(:twilight_struggle_tournament, template_win: "parent template") }
      let(:tournament) do
        create(
          :twilight_struggle_tournament,
          parent:,
          template_win: ""
        )
      end

      it "falls through to the parent's template" do
        expect(config.template_win).to eq("parent template")
      end
    end

    context "when nothing in the chain has a template" do
      let(:tournament) { create(:twilight_struggle_tournament) }

      it "returns the i18n default" do
        expect(config.template_win).to eq(I18n.t("twilight_struggle.default_template.win"))
      end
    end
  end

  describe "#template_tie" do
    context "when the tournament has its own template" do
      let(:tournament) { create(:twilight_struggle_tournament, template_tie: "own template") }

      it "returns its own template" do
        expect(config.template_tie).to eq("own template")
      end
    end

    context "when the tournament has none but the parent does" do
      let(:parent) { create(:twilight_struggle_tournament, template_tie: "parent template") }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      it "inherits the parent's template" do
        expect(config.template_tie).to eq("parent template")
      end
    end

    context "when the tournament's own template is blank" do
      let(:parent) { create(:twilight_struggle_tournament, template_tie: "parent template") }
      let(:tournament) do
        create(
          :twilight_struggle_tournament,
          parent:,
          template_tie: ""
        )
      end

      it "falls through to the parent's template" do
        expect(config.template_tie).to eq("parent template")
      end
    end

    context "when nothing in the chain has a template" do
      let(:tournament) { create(:twilight_struggle_tournament) }

      it "returns the i18n default" do
        expect(config.template_tie).to eq(I18n.t("twilight_struggle.default_template.tie"))
      end
    end
  end

  describe "#template_video" do
    context "when the tournament has its own template" do
      let(:tournament) { create(:twilight_struggle_tournament, template_video: "own template") }

      it "returns its own template" do
        expect(config.template_video).to eq("own template")
      end
    end

    context "when the tournament has none but the parent does" do
      let(:parent) { create(:twilight_struggle_tournament, template_video: "parent template") }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      it "inherits the parent's template" do
        expect(config.template_video).to eq("parent template")
      end
    end

    context "when the tournament's own template is blank" do
      let(:parent) { create(:twilight_struggle_tournament, template_video: "parent template") }
      let(:tournament) do
        create(
          :twilight_struggle_tournament,
          parent:,
          template_video: ""
        )
      end

      it "falls through to the parent's template" do
        expect(config.template_video).to eq("parent template")
      end
    end

    context "when nothing in the chain has a template" do
      let(:tournament) { create(:twilight_struggle_tournament) }

      it "returns the i18n default" do
        expect(config.template_video).to eq(I18n.t("twilight_struggle.default_template.video"))
      end
    end
  end

  describe "#ping_players?" do
    context "when the tournament sets true" do
      let(:tournament) { create(:twilight_struggle_tournament, ping_players: true) }

      it "is true" do
        expect(config.ping_players?).to be(true)
      end
    end

    context "when the child explicitly sets false and the parent sets true" do
      let(:parent) { create(:twilight_struggle_tournament, ping_players: true) }
      let(:tournament) do
        create(
          :twilight_struggle_tournament,
          parent:,
          ping_players: false
        )
      end

      it "is false" do
        expect(config.ping_players?).to be(false)
      end
    end

    context "when the child is nil and the parent sets true" do
      let(:parent) { create(:twilight_struggle_tournament, ping_players: true) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      it "inherits true from the parent" do
        expect(config.ping_players?).to be(true)
      end
    end

    context "when nothing in the chain sets it" do
      let(:tournament) { create(:twilight_struggle_tournament) }

      it "is false" do
        expect(config.ping_players?).to be(false)
      end
    end
  end
end
