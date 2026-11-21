# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Toast do
  subject(:html) { described_class.new(level:, message: "Saved.").call }

  let(:level) { "notice" }

  it "puts the card in a collapsible row so a dismissed toast can fold away" do
    row = Nokogiri::HTML5.fragment(html).at_css("[data-controller='toast']")

    expect(row["class"]).to include("toast-slot")
    expect(row.at_css("div.min-h-0 > div.pointer-events-auto")).to be_present
  end

  context "with the warning level" do
    let(:level) { "warning" }

    it "renders the warning icon and tone" do
      expect(html).to include("bg-warning-solid").and include("text-warning-text")
    end

    it "stays until dismissed" do
      expect(html).to include('data-toast-sticky-value="true"')
    end
  end

  context "with the notice level" do
    let(:level) { "notice" }

    it "renders the success tone and times out" do
      expect(html).to include("bg-success-solid")
      expect(html).not_to include("data-toast-sticky-value")
    end

    it "stays out of Turbo's page cache, so Back never replays it" do
      expect(html).to include("data-turbo-temporary")
    end
  end
end
