# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::FieldHelp do
  subject(:html) { described_class.new.call { "Pick a channel." } }

  it "renders the block content inside a p carrying the shared classes" do
    expect(html).to include("<p").and include('class="mt-1.5 text-xs text-text-muted"').and include("Pick a channel.")
  end
end
