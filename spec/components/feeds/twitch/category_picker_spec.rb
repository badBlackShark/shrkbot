# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Twitch::CategoryPicker do
  include_context "component view context"

  subject(:select) do
    Nokogiri::HTML.fragment(
      described_class.new(name: "picks[]", server_configuration:, placeholder: "Pick", multiple: true, max_items: 3, selected:, error_id:).render_in(view_context)
    ).at_css("select")
  end

  let(:server_configuration) { create(:server_configuration) }
  let(:selected) { [{"id" => "1", "name" => "Hades II"}] }
  let(:error_id) { nil }

  it "searches this server's Twitch categories, showing the caller's placeholder and the shared failure copy" do
    expect(select["data-tom-select-search-url-value"]).to eq(Rails.application.routes.url_helpers.server_twitch_categories_path(server_configuration.discord_id))
    expect(select["data-tom-select-placeholder-value"]).to eq("Pick")
    expect(select["data-tom-select-search-failed-value"]).to eq("Twitch didn't answer. Try again in a minute.")
    expect(select["data-tom-select-max-items-value"]).to eq("3")
    expect(select["multiple"]).to be_present
  end

  it "preselects the given categories as dumped id and name" do
    expect(select.css("option[selected]").map { |option| [option["value"], option.text] }).to eq([['{"id":"1","name":"Hades II"}', "Hades II"]])
  end
end
