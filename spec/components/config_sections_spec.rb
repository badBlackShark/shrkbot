# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ConfigSections do
  subject(:html) do
    described_class.new(key:, save_error:, data:).call { "Section body" }
  end

  let(:key) { "welcomes" }
  let(:save_error) { nil }
  let(:data) { {} }

  it "wraps the content in a div with the key-derived id" do
    expect(html).to include('id="welcomes-config"')
  end

  it "renders the yielded block content" do
    expect(html).to include("Section body")
  end

  it "renders an empty save-error target and no danger callout" do
    expect(html).to include('id="welcomes-save-error"')
    expect(html).not_to include("bg-danger-soft")
  end

  context "with data attributes" do
    let(:data) { {controller: "welcome-preview"} }

    it "renders the data attributes" do
      expect(html).to include('data-controller="welcome-preview"')
    end
  end

  context "with an save_error" do
    let(:save_error) { "Something went wrong." }

    it "renders a danger callout with the error" do
      expect(html).to include("bg-danger-soft").and include("Something went wrong.")
    end
  end
end
