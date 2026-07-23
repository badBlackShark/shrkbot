# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::LifetimeCard do
  subject(:html) { described_class.new(value: 240).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }

  it "renders the post lifetime label and stepper with the given value" do
    expect(html).to include("Post lifetime")
    expect(html).to include('name="lfg[post_lifetime_minutes]"')
    expect(html).to include('value="240"')
  end

  it "explains the recommended default in human terms" do
    expect(html).to include("360 minutes, which is 6 hours")
  end
end
