# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ResetButton do
  include_context "component view context"

  subject(:html) { described_class.new(label: "Reset to default", data: {action: "x#reset"}).render_in(view_context) }

  it "renders a labelled icon button with a tooltip and the given data" do
    expect(html).to include('aria-label="Reset to default"', 'data-action="x#reset"', 'type="button"')
    expect(Nokogiri::HTML5.fragment(html).at_css("[role=tooltip]").text).to eq("Reset to default")
  end

  context "with the segment shape" do
    subject(:html) { described_class.new(label: "Reset", data: {}, shape: :segment).render_in(view_context) }

    it "joins the group border instead of drawing its own box" do
      classes = Nokogiri::HTML5.fragment(html).at_css("button")["class"].split

      expect(classes).to include("border-l")
      expect(classes).not_to include("rounded-control")
    end
  end
end
