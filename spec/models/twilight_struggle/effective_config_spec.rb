# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::EffectiveConfig do
  subject(:config) { described_class.new(tournament, server_configuration) }

  let(:server_configuration) { create(:server_configuration) }

  describe "#channel_id" do
    context "when this server has its own destination with a channel" do
      let(:tournament) { create(:twilight_struggle_tournament) }

      before { create(:twilight_struggle_destination, tournament:, server_configuration:, discord_channel_id: 111) }

      it "resolves its own channel id" do
        expect(config.channel_id).to eq(111)
      end
    end

    context "when this server has no destination but the parent tournament does" do
      let(:parent) { create(:twilight_struggle_tournament) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      before { create(:twilight_struggle_destination, tournament: parent, server_configuration:, discord_channel_id: 222) }

      it "inherits the parent's channel id" do
        expect(config.channel_id).to eq(222)
      end
    end

    context "when a grandparent has the channel and the parent's destination sets nothing" do
      let(:grandparent) { create(:twilight_struggle_tournament) }
      let(:parent) { create(:twilight_struggle_tournament, parent: grandparent) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      before do
        create(:twilight_struggle_destination, tournament: grandparent, server_configuration:, discord_channel_id: 333)
        create(:twilight_struggle_destination, tournament: parent, server_configuration:)
      end

      it "inherits the grandparent's channel id" do
        expect(config.channel_id).to eq(333)
      end
    end

    context "when a different server subscribes to the same tournament" do
      let(:tournament) { create(:twilight_struggle_tournament) }
      let(:other_server) { create(:server_configuration) }

      before { create(:twilight_struggle_destination, tournament:, server_configuration: other_server, discord_channel_id: 444) }

      it "never leaks the other server's channel into this one" do
        expect(config.channel_id).to be_nil
      end
    end

    context "when nothing in the chain has a destination for this server" do
      let(:parent) { create(:twilight_struggle_tournament) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      it "returns nil" do
        expect(config.channel_id).to be_nil
      end
    end

    context "when the tournament is nil" do
      let(:tournament) { nil }

      it "returns nil" do
        expect(config.channel_id).to be_nil
      end
    end
  end

  describe "#template_win" do
    let(:tournament) { create(:twilight_struggle_tournament) }

    context "when this server's destination has its own template" do
      before { create(:twilight_struggle_destination, tournament:, server_configuration:, template_win: "own template") }

      it "returns its own template" do
        expect(config.template_win).to eq("own template")
      end
    end

    context "when this server's destination has none but the parent's does" do
      let(:parent) { create(:twilight_struggle_tournament) }
      let(:tournament) { create(:twilight_struggle_tournament, parent:) }

      before do
        create(:twilight_struggle_destination, tournament: parent, server_configuration:, template_win: "parent template")
        create(:twilight_struggle_destination, tournament:, server_configuration:, template_win: "")
      end

      it "falls through to the parent's template" do
        expect(config.template_win).to eq("parent template")
      end
    end

    context "when nothing in the chain sets a template" do
      it "returns the i18n default" do
        expect(config.template_win).to eq(I18n.t("twilight_struggle.default_template.win"))
      end
    end
  end

  describe "#template_tie" do
    let(:tournament) { create(:twilight_struggle_tournament) }

    it "returns the i18n default when unset" do
      expect(config.template_tie).to eq(I18n.t("twilight_struggle.default_template.tie"))
    end

    it "returns this server's own template" do
      create(:twilight_struggle_destination, tournament:, server_configuration:, template_tie: "own template")

      expect(config.template_tie).to eq("own template")
    end
  end

  describe "#template_video" do
    let(:tournament) { create(:twilight_struggle_tournament) }

    it "returns the i18n default when unset" do
      expect(config.template_video).to eq(I18n.t("twilight_struggle.default_template.video"))
    end

    it "returns this server's own template" do
      create(:twilight_struggle_destination, tournament:, server_configuration:, template_video: "own template")

      expect(config.template_video).to eq("own template")
    end
  end

  describe "#ping_players?" do
    let(:parent) { create(:twilight_struggle_tournament) }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }

    it "is true when this server's destination sets true" do
      create(:twilight_struggle_destination, tournament:, server_configuration:, ping_players: true)

      expect(config.ping_players?).to be(true)
    end

    it "is false when this server's destination explicitly sets false and the parent sets true" do
      create(:twilight_struggle_destination, tournament: parent, server_configuration:, ping_players: true)
      create(:twilight_struggle_destination, tournament:, server_configuration:, ping_players: false)

      expect(config.ping_players?).to be(false)
    end

    it "inherits true from the parent when this server's destination leaves it nil" do
      create(:twilight_struggle_destination, tournament: parent, server_configuration:, ping_players: true)
      create(:twilight_struggle_destination, tournament:, server_configuration:)

      expect(config.ping_players?).to be(true)
    end

    it "is false when nothing in the chain sets it" do
      expect(config.ping_players?).to be(false)
    end
  end

  describe "#inherited_from" do
    let(:grandparent) { create(:twilight_struggle_tournament) }
    let(:parent) { create(:twilight_struggle_tournament, parent: grandparent) }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }

    it "names the nearest ancestor this server is subscribed to" do
      create(:twilight_struggle_destination, tournament: grandparent, server_configuration:)

      expect(config.inherited_from).to eq(grandparent)
    end

    it "prefers the closer ancestor over a farther one" do
      create(:twilight_struggle_destination, tournament: parent, server_configuration:)
      create(:twilight_struggle_destination, tournament: grandparent, server_configuration:)

      expect(config.inherited_from).to eq(parent)
    end

    it "is nil when this server subscribes nowhere in the chain" do
      expect(config.inherited_from).to be_nil
    end
  end

  describe "EffectiveConfig.new(nil, server_configuration)" do
    subject(:config) { described_class.new(nil, server_configuration) }

    it "is safe and returns the defaults" do
      expect(config.channel_id).to be_nil
      expect(config.template_win).to eq(I18n.t("twilight_struggle.default_template.win"))
      expect(config.ping_players?).to be(false)
      expect(config.inherited_from).to be_nil
    end
  end
end
