# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::DefaultsCard do
  subject(:html) { described_class.new(settings:, role_options:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:config) { create(:server_configuration) }
  let(:settings) { create(:lfg_settings, server_configuration: config, default_min_membership_days: 5) }
  let(:role_options) { [Components::TomSelect::Option.for(value: 222, label: "Member")] }

  it "renders the required and excluded role selects" do
    expect(html).to include("Required roles")
    expect(html).to include("Excluded roles")
    expect(html).to include(">Member<")
  end

  it "renders the min-days input with its stored value" do
    expect(html).to include('name="lfg[default_min_membership_days]"')
    expect(html).to include('value="5"')
  end

  it "does not render a NumberStepper for min-days" do
    expect(html).not_to include("Recommended default")
  end
end
