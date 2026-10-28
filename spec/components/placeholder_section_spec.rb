# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PlaceholderSection do
  subject(:html) { described_class.new.render_in(view_context) { "chips" } }

  let(:view_context) { ApplicationController.new.view_context }

  it "heads the block with the copy hint" do
    expect(html).to include("Placeholders (click to copy)")
  end

  it "wraps the block in the clipboard controller" do
    expect(html).to include('data-controller="clipboard"').and include("chips")
  end
end
