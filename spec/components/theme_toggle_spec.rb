# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ThemeToggle do
  include_context "component view context"

  subject(:html) { described_class.new.render_in(view_context) }

  it "renders a button with the theme controller" do
    expect(html).to include('data-controller="theme"')
  end

  it "sets an aria-label for the toggle action" do
    expect(html).to include('aria-label="Toggle dark mode"')
  end
end
