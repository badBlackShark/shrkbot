# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::CategoryWatcher do
  let(:games) { instance_double(Integrations::Twitch::Games) }
  let(:game) { Integrations::Twitch::Game.new(id: "27471", name: "Mine craft", box_art_url: "https://example.test/box.jpg") }
  let(:target) do
    Integrations::Target.new(
      external_id: "27471",
      name: "Mine craft",
      image_url: "https://example.test/box.jpg",
      url: "https://www.twitch.tv/directory/game/Mine%20craft"
    )
  end

  describe ".resolve" do
    subject(:resolved) { described_class.resolve(" 27471 ", games:) }

    before do
      allow(games).to receive(:find).with("27471").and_return(game)
    end

    it "looks the id up and maps the game to a target" do
      expect(resolved).to eq(target)
    end

    context "when the input is not an id" do
      subject(:resolved) { described_class.resolve("minecraft", games:) }

      it "raises InvalidReference without asking Twitch" do
        expect { resolved }.to raise_error(Integrations::InvalidReference)
        expect(games).not_to have_received(:find)
      end
    end

    context "when Twitch has no such category" do
      before do
        allow(games).to receive(:find).with("27471").and_return(nil)
      end

      it "raises NotFound" do
        expect { resolved }.to raise_error(Integrations::NotFound)
      end
    end
  end

  describe ".refresh" do
    subject(:refreshed) { described_class.refresh(["27471"], games:) }

    before do
      allow(games).to receive(:for).with(["27471"]).and_return([game])
    end

    it "maps each game to a target" do
      expect(refreshed).to eq([target])
    end
  end

  describe ".followed" do
    subject(:followed) { described_class.followed }

    let!(:category) { create(:integration_watch, watcher: described_class.name, external_id: "1") }

    before do
      create(:integration_watch, :twitch)
      allow(Integrations::Watch).to receive(:demanded).and_return(Integrations::Watch.all)
    end

    it "is the demanded category watches only" do
      expect(followed).to contain_exactly(category)
    end
  end
end
