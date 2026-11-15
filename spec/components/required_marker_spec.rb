# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::RequiredMarker do
  subject(:html) { described_class.new.call }

  let(:span) { Nokogiri::HTML.fragment(html).at_css("span") }

  it "renders an asterisk in the readable danger colour" do
    expect(span.text).to eq("*")
    expect(span["class"].split).to include("text-danger-text")
  end

  it "hides the asterisk from screen readers" do
    expect(span["aria-hidden"]).to eq("true")
  end
end
