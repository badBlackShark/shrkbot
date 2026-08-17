# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SettingRow do
  subject(:html) do
    described_class.new(label: "Ping staff on detection", help:).call { "CONTROL" }
  end

  let(:help) { "Mentions your staff role when Shield acts." }

  it "renders the label" do
    expect(html).to include("Ping staff on detection")
  end

  it "renders the help text" do
    expect(html).to include("Mentions your staff role when Shield acts.")
  end

  it "renders the yielded control" do
    expect(html).to include("CONTROL")
  end

  it "labels the setting with a paragraph, leaving the accessible name to the control" do
    expect(html).not_to include("<label")
  end

  context "without help text" do
    let(:help) { nil }

    it "renders only the label" do
      expect(html).to include("Ping staff on detection")
      expect(html).not_to include("text-text-secondary")
    end
  end
end
