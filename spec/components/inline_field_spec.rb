# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::InlineField do
  subject(:html) do
    described_class.new(label: "Treat accounts as new for").call { "CONTROL" }
  end

  it "renders the label before the yielded control" do
    expect(html).to match(/Treat accounts as new for.*CONTROL/m)
  end

  it "labels the setting with a span, leaving the accessible name to the control" do
    expect(html).to match(%r{<span[^>]*>Treat accounts as new for</span>})
  end
end
