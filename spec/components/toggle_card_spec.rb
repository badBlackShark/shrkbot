# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ToggleCard do
  subject(:html) do
    described_class.new(
      name: "welcomes[ping_on_join]",
      checked: true,
      label: "Ping on join",
      help: "Ping new members."
    ).call
  end

  it "renders the label and help text" do
    expect(html).to include("Ping on join").and include("Ping new members.")
  end

  it "renders a checked toggle wired to the given field name" do
    expect(html).to include('name="welcomes[ping_on_join]"')
    expect(html).to include('type="checkbox"').and include("checked")
  end
end
