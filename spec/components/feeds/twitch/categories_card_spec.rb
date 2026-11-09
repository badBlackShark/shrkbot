# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Twitch::CategoriesCard do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(described_class.new(subscription:).render_in(view_context)) }

  let(:subscription) { build(:feed_subscription, :twitch) }
  let(:categories) { [{"id" => "1", "name" => "Hades II"}, {"id" => "2", "name" => "Just Chatting"}] }
  let(:select) { document.at_css("select[name='subscription[categories][]']") }

  before { subscription.settings.categories = categories }

  it "preselects the saved categories with their id and name as the value" do
    expect(select.css("option[selected]").map { |option| [option["value"], option.text] }).to eq(
      [['{"id":"1","name":"Hades II"}', "Hades II"], ['{"id":"2","name":"Just Chatting"}', "Just Chatting"]]
    )
  end

  it "searches Twitch through this server's categories endpoint" do
    expect(select["data-tom-select-search-url-value"]).to eq(Rails.application.routes.url_helpers.server_twitch_categories_path(subscription.server_configuration.discord_id))
    expect(select["multiple"]).to be_present
  end

  it "submits an empty entry first so clearing every category still reaches the server" do
    names = document.css("[name='subscription[categories][]']")

    expect(names.first["type"]).to eq("hidden")
    expect(names.first["value"]).to eq("")
    expect(names.last).to eq(select)
  end

  context "without saved categories" do
    let(:categories) { [] }

    it "selects nothing" do
      expect(select.css("option")).to be_empty
    end
  end

  it "ends with the switched-away choice, folded into a closed settings disclosure remembered per channel" do
    wrapper = document.at_css("[data-controller='disclosure']")
    details = wrapper.at_css("details")

    expect(wrapper.parent.element_children.last).to eq(wrapper)

    expect(wrapper["data-disclosure-key-value"]).to eq("feeds-switched-away-#{subscription.watch.external_id}")
    expect(details["open"]).to be_nil
    expect(details.at_css("summary").text).to include("Settings")
    expect(details.at_css("input[name='subscription[switched_away]']")).to be_present
  end
end
