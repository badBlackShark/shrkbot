# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::TargetCard do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(host.new(target, plugin_key).render_in(view_context)) }

  let(:host) do
    Class.new(Components::Base) do
      def initialize(target, plugin_key)
        @target = target
        @plugin_key = plugin_key
      end

      def view_template
        render Components::Feeds::TargetCard.new(target: @target, plugin_key: @plugin_key) do
          plain "Slotted action"
        end
      end
    end
  end
  let(:plugin_key) { :steam }
  let(:target) { build(:integration_watch, external_id: "1145350", name: "Hades II", image_url: "https://example.test/hades.jpg") }

  it "shows the name and an eagerly loaded picture" do
    expect(document.at_css("h1").text).to eq("Hades II")
    expect(document.at_css("img[src='https://example.test/hades.jpg']")["loading"]).to eq("eager")
  end

  it "puts the given action inside the card" do
    expect(document.text).to include("Slotted action")
  end

  it "captions a Steam game with its app id" do
    expect(document.text).to include("Steam app 1145350")
  end

  context "with Twitch" do
    let(:plugin_key) { :twitch }

    it "has no caption" do
      expect(document.css("p")).to be_empty
    end
  end
end
