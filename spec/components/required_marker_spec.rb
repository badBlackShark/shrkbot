# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::RequiredMarker do
  subject(:html) { described_class.new.call }

  it "renders a red asterisk" do
    expect(html).to include("<span").and include("text-danger").and include("*")
  end
end
