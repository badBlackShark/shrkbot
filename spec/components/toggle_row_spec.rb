# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ToggleRow do
  subject(:html) do
    described_class.new(name: "welcomes[ping_on_join]", checked: true, label: "Ping on join", help:).call
  end

  let(:help) { "Ping new members." }

  it "renders a checked toggle wired to the given field name" do
    expect(html).to include('name="welcomes[ping_on_join]"')
    expect(html).to include('type="checkbox"').and include("checked")
  end

  it "renders the label and the help text" do
    expect(html).to include("Ping on join").and include("Ping new members.")
  end

  context "without help text" do
    let(:help) { nil }

    it "renders the label without an empty help paragraph" do
      expect(html).to include("Ping on join")
      expect(html).not_to include("text-text-secondary")
    end
  end
end
