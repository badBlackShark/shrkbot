# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Steam::LanguageCard do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(described_class.new(subscription:).render_in(view_context)) }

  let(:subscription) { build(:steam_feed_subscription, languages: %w[de ru]) }

  it "marks the subscription's languages as selected" do
    selected = document.css("select[name='subscription[languages][]'] option[selected]").map { |option| option["value"] }

    expect(selected).to match_array(%w[de ru])
  end

  it "labels the options with language names" do
    expect(document.at_css("option[value='de']").text).to eq("German")
  end

  it "submits a blank value so every language can be cleared" do
    expect(document.at_css("input[type=hidden][name='subscription[languages][]']")["value"]).to eq("")
  end

  describe "the English note" do
    let(:region) { document.at_css("[data-controller=live-warning]") }
    let(:note) { region.at_css("[data-live-warning-target=callout]") }

    let(:field) { region.parent }
    let(:help) { field.at_xpath("./p") }

    it "sits below the language select and its help" do
      expect(help.xpath("following-sibling::*")).to include(region)
      expect(help.xpath("preceding-sibling::*").any? { |node| node.xpath("descendant-or-self::select[@name='subscription[languages][]']").any? }).to be(true)
    end

    it "announces itself through a status region" do
      expect(region["role"]).to eq("status")
    end

    it "watches the language field for a pick without English" do
      expect(JSON.parse(region["data-live-warning-fields-value"])).to eq(["subscription[languages][]"])
      expect(region["data-live-warning-rule-value"]).to eq("excludes-all")
      expect(JSON.parse(region["data-live-warning-list-value"])).to eq(["en"])
    end

    it "shows for languages without English" do
      expect(note.key?("hidden")).to be(false)
    end

    context "when English is among the languages" do
      let(:subscription) { build(:steam_feed_subscription, languages: %w[de en]) }

      it "is hidden" do
        expect(note.key?("hidden")).to be(true)
      end
    end

    context "when no language is picked" do
      let(:subscription) { build(:steam_feed_subscription, languages: []) }

      it "is hidden" do
        expect(note.key?("hidden")).to be(true)
      end
    end
  end
end
