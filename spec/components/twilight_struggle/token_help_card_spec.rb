# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::TokenHelpCard do
  subject(:html) { described_class.new.render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:fragment) { Nokogiri::HTML5.fragment(html) }

  it "renders every token in GROUPS as a copy button" do
    described_class::GROUPS.values.flatten.each do |token|
      expect(html).to include(%(data-clipboard-text-param="{#{token}}"))
    end
  end

  it "labels each group" do
    expect(html).to include("Game").and include("USA").and include("USSR").and include("Winner").and include("Loser")
  end

  it "starts closed and remembers the reader's choice" do
    details = fragment.at_css("details")
    expect(details.key?("open")).to be(false)
    expect(details["data-disclosure-key-value"]).to eq("twilight-struggle-placeholders")
  end

  it "names the card in its summary, so it reads while closed" do
    expect(fragment.at_css("summary").text).to include("Placeholders (click to copy)")
  end

  it "puts the tie note between the USSR and Winner groups" do
    tie_note = html.index("All following placeholders are empty on a tie.")
    expect(html.index(">USSR<")).to be < tie_note
    expect(tie_note).to be < html.index(">Winner<")
  end
end
