# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::SettingsDisclosure do
  include_context "component view context"

  subject(:details) do
    html = described_class.new.render_in(view_context) { "BODY" }
    Nokogiri::HTML5.fragment(html).at_css("details")
  end

  it "is the disclosure controller's closed details, toggled by its summary" do
    expect(details["data-disclosure-target"]).to eq("details")
    expect(details["open"]).to be_nil
    expect(details.at_css("summary")["data-action"]).to eq("click->disclosure#toggle")
    expect(details.at_css("summary").text).to include("Settings")
  end

  it "renders the block below the summary" do
    expect(details.at_css("summary + div").text).to eq("BODY")
  end
end
