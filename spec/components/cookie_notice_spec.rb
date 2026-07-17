# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::CookieNotice do
  include_context "component view context"

  subject(:html) { described_class.new.render_in(view_context) }

  it "renders hidden by default" do
    expect(html).to include("hidden")
  end

  it "wires the Stimulus controller and dismiss action" do
    expect(html).to include('data-controller="cookie-notice"').and include("cookie-notice#dismiss")
  end

  it "shows the no-tracking message and dismiss label" do
    expect(html).to include("only set technical cookies").and include("Oh, nice!")
  end
end
