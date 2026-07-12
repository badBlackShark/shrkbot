# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::AccountAgeCard do
  include_context "component view context"

  subject(:html) { described_class.new(new_account_age_days:).render_in(view_context) }

  let(:new_account_age_days) { 30 }

  it "renders the stepper with the correct field name" do
    expect(html).to include('name="moderation[new_account_age_days]"')
  end

  it "renders the label and help text" do
    expect(html).to include("New account age")
    expect(html).to include("How recently a Discord account")
  end

  it "renders the configured value" do
    expect(html).to include('value="30"')
  end

  context "with a custom value" do
    let(:new_account_age_days) { 90 }

    it "renders that value" do
      expect(html).to include('value="90"')
    end
  end
end
