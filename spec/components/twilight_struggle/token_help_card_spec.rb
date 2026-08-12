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
end
