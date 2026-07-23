# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::CooldownCard do
  subject(:html) { described_class.new(value: 120).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }

  it "renders the cooldown label and stepper with the given value" do
    expect(html).to include("Cooldown")
    expect(html).to include('name="lfg[cooldown_seconds]"')
    expect(html).to include('value="120"')
  end

  it "explains the recommended default in human terms" do
    expect(html).to include("300 seconds, which is 5 minutes")
  end
end
