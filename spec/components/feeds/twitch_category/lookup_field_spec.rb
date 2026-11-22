# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::TwitchCategory::LookupField do
  include_context "component view context"

  subject(:select) { render_field(value).at_css("select") }

  let(:server_configuration) { create(:server_configuration) }
  let(:value) { nil }
  let(:error_id) { nil }

  def render_field(typed)
    Nokogiri::HTML.fragment(described_class.new(name: :category, value: typed, error_id:, server_configuration:).render_in(view_context))
  end

  def picked_options(typed)
    render_field(typed).css("option[selected]").map(&:text)
  end

  it "is a single pick that searches Twitch through this server's categories endpoint" do
    expect(select["name"]).to eq("category")
    expect(select["multiple"]).to be_nil
    expect(select["data-tom-select-search-url-value"]).to eq(Rails.application.routes.url_helpers.server_twitch_categories_path(server_configuration.discord_id))
    expect(select["data-tom-select-max-items-value"]).to eq("1")
    expect(select["aria-label"]).to eq("Category")
  end

  context "with the category picked before" do
    let(:value) { Feeds::Twitch::CategoryValue.dump({"id" => "1", "name" => "Hades II"}) }

    it "keeps it picked, with the dumped pick as its value" do
      expect(select.css("option[selected]").map { |option| [option["value"], option.text] }).to eq([[value, "Hades II"]])
    end
  end

  it "has nothing picked for no value or a value that is not a picked category" do
    picked = [nil, "1"].map { |typed| picked_options(typed) }

    expect(picked).to eq([[], []])
  end

  context "with a problem to describe" do
    let(:error_id) { "feed-lookup-error" }

    it "marks the picker invalid and points at the message" do
      expect(select["aria-invalid"]).to eq("true")
      expect(select["aria-describedby"]).to eq("feed-lookup-error")
    end
  end

  context "without a problem" do
    it "leaves the picker unmarked" do
      expect(select["aria-invalid"]).to be_nil
      expect(select["aria-describedby"]).to be_nil
    end
  end
end
