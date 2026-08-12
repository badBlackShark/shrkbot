# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::TokenHelpCard do
  subject(:html) { described_class.new.render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }

  it "renders every token in GROUPS as a copy button" do
    described_class::GROUPS.values.flatten.each do |token|
      expect(html).to include(%(data-clipboard-text-param="{#{token}}"))
    end
  end

  it "labels each group" do
    expect(html).to include("Game").and include("USA").and include("USSR").and include("Winner").and include("Loser")
  end

  it "makes the chips buttons rather than focusable code elements" do
    expect(html).to include('type="button"')
    expect(html).not_to include('tabindex="0"')
  end

  it "hands the copy confirmation labels to the controller" do
    expect(html).to include('data-clipboard-copied-label-value="Copied!"')
  end

  it "carries a live region so the copy is announced to screen readers" do
    expect(html).to include('role="status"').and include('data-clipboard-target="announcer"')
  end
end
