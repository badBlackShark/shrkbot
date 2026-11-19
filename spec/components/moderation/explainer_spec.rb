# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::Explainer do
  include_context "component view context"

  subject(:html) { described_class.new(title: "How it works", rows: ["First", "Second"], ordered:, id:).render_in(view_context) }

  let(:ordered) { false }
  let(:id) { nil }
  let(:page) { Nokogiri::HTML.fragment(html) }

  it "renders the title in a disclosure summary and one row per entry" do
    expect(page.at_css("details[data-controller='disclosure'] > summary").text).to include("How it works")
    expect(page.css("li").map(&:text)).to eq(%w[First Second])
  end

  it "lists the rows with dashes and gives the wrapper no id" do
    expect(page.at_css("ul")).to be_present
    expect(page.at_css("ol")).to be_nil
    expect(page.at_css("div[id]")).to be_nil
  end

  context "when ordered" do
    let(:ordered) { true }

    it "numbers the rows" do
      expect(page.at_css("ol")).to be_present
      expect(page.at_css("ul")).to be_nil
    end
  end

  context "with an id" do
    let(:id) { "matching" }

    it "puts the id on the wrapper" do
      expect(page.at_css("div#matching > details")).to be_present
    end
  end
end
