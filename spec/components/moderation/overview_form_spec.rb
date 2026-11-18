# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::OverviewForm do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let(:context) do
    instance_double(
      Moderation::OverviewContext,
      staff_role_id: nil,
      ping_staff: true,
      new_account_age_days: 30,
      permission_warning?: false
    )
  end

  subject(:html) do
    described_class.new(
      server_configuration: config,
      context:
    ).render_in(view_context)
  end

  it "renders the staff role card" do
    expect(html).to include("moderation[staff_role_id]")
  end

  it "renders the staff ping toggle" do
    expect(html).to include("moderation[ping_staff]")
  end

  it "renders the account age stepper" do
    expect(html).to include("moderation[new_account_age_days]")
  end

  context "with the matching explainer" do
    let(:explainer) { Nokogiri::HTML.fragment(html).at_css("#matching details[data-controller='disclosure']") }

    it "is a disclosure that its summary toggles" do
      expect(explainer.at_xpath("./summary")["data-action"]).to eq("click->disclosure#toggle")
    end
  end
end
