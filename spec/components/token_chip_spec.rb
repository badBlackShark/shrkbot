# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TokenChip do
  subject(:html) { described_class.new(token: "user", description: "Expands to a mention.").call }

  it "braces the bare token name for the label" do
    expect(html).to include(">{user}<")
  end

  it "copies the braced token" do
    expect(html).to include('data-clipboard-text-param="{user}"').and include('data-action="clipboard#copy"')
  end

  it "renders a button rather than a focusable code element" do
    expect(html).to include('type="button"')
    expect(html).not_to include('tabindex="0"')
  end

  it "describes the token in a tooltip" do
    expect(html).to include('role="tooltip"').and include("Expands to a mention.")
  end
end
