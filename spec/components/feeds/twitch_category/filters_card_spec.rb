# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::TwitchCategory::FiltersCard do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(described_class.new(subscription:).render_in(view_context)) }

  let(:subscription) { build(:feed_subscription, :twitch_category) }
  let(:languages) { document.at_css("select[name='subscription[languages][]']") }
  let(:excluded) { document.at_css("select[name='subscription[excluded_channels][]']") }

  before { subscription.settings.assign_attributes(min_viewers: 25, languages: %w[de en], excluded_channels: %w[streamer_one]) }

  it "says what the filters see before offering them" do
    expect(document.text).to include("100 most-watched streams")
    expect(document.text.index("100 most-watched")).to be < document.text.index("Only post streams with at least")
  end

  it "counts the streams that would post, above the top-100 note" do
    expect(document.at_css("[data-controller='category-counter']")).to be_present
    expect(document.text.index("Counting streams")).to be < document.text.index("100 most-watched")
  end

  it "holds the stored floor in a stepper that can't go below zero" do
    input = document.at_css("input[name='subscription[min_viewers]']")

    expect(input["value"]).to eq("25")
    expect(input["min"]).to eq("0")
  end

  it "preselects the stored languages under their English names" do
    expect(languages["multiple"]).to be_present
    expect(languages.css("option[selected]").map { |option| [option["value"], option.text] }).to contain_exactly(%w[de German], %w[en English])
  end

  it "offers every language the settings accept" do
    expect(languages.css("option").map { |option| option["value"] }).to match_array(Feeds::TwitchCategory::LANGUAGES)
  end

  it "lets excluded channels be typed in, with the stored ones preselected" do
    expect(excluded).to have_attribute("data-tom-select-create-value")
    expect(excluded.css("option[selected]").map { |option| option["value"] }).to eq(%w[streamer_one])
  end

  it "submits an empty entry before each list so clearing it still reaches the server" do
    %w[languages excluded_channels].each do |setting|
      names = document.css("[name='subscription[#{setting}][]']")

      expect(names.first.attributes.slice("type", "value").transform_values(&:value)).to eq("type" => "hidden", "value" => "")
      expect(names.last.name).to eq("select")
    end
  end
end
