# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::TwitchCategory::LookupField do
  include_context "component view context"

  subject(:select) { Nokogiri::HTML.fragment(described_class.new(name: :category, value:, server_configuration:).render_in(view_context)).at_css("select") }

  let(:server_configuration) { create(:server_configuration) }
  let(:value) { nil }

  it "is a single pick that searches Twitch through this server's categories endpoint" do
    expect(select["name"]).to eq("category")
    expect(select["multiple"]).to be_nil
    expect(select["data-tom-select-search-url-value"]).to eq(Rails.application.routes.url_helpers.server_twitch_categories_path(server_configuration.discord_id))
    expect(select["data-tom-select-max-items-value"]).to eq("1")
    expect(select["aria-label"]).to eq("Category")
  end

  it "has nothing picked" do
    expect(select.css("option[selected]")).to be_empty
  end

  context "with the category picked before" do
    let(:value) { Feeds::Twitch::CategoryValue.dump({"id" => "1", "name" => "Hades II"}) }

    it "keeps it picked, with the dumped pick as its value" do
      expect(select.css("option[selected]").map { |option| [option["value"], option.text] }).to eq([[value, "Hades II"]])
    end
  end

  context "with a value that is not a picked category" do
    let(:value) { "1" }

    it "picks nothing" do
      expect(select.css("option[selected]")).to be_empty
    end
  end
end
