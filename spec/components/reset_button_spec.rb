# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ResetButton do
  include_context "component view context"

  subject(:html) { described_class.new(label: "Reset to default", data: {action: "x#reset"}).render_in(view_context) }

  it "renders a labelled icon button with a tooltip and the given data" do
    expect(html).to include('aria-label="Reset to default"', 'data-action="x#reset"', 'type="button"')
    expect(html.scan("Reset to default").size).to be >= 2
  end
end
