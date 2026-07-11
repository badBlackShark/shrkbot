# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PageHeading do
  subject(:html) { described_class.new(**options).call }

  let(:options) { {title: "My Title", subtitle: "A short description"} }

  it "renders the title in an h1" do
    expect(html).to include("<h1").and include("My Title")
  end

  it "renders the subtitle in a paragraph" do
    expect(html).to include("<p").and include("A short description")
  end

  it "applies the display font and size classes to the heading" do
    expect(html).to include("font-display").and include("text-2xl").and include("font-bold")
  end

  it "applies the secondary text tone to the subtitle" do
    expect(html).to include("text-text-secondary")
  end

  context "with different content" do
    let(:options) { {title: "Server Settings", subtitle: "Configure your server"} }

    it "renders the given title and subtitle" do
      expect(html).to include("Server Settings").and include("Configure your server")
    end
  end
end
