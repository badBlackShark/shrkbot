# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::PingableRolesCard do
  subject(:html) { described_class.new(settings:, context:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:config) { create(:server_configuration) }
  let(:settings) { create(:lfg_settings, server_configuration: config) }
  let(:role_options) { [Components::TomSelect::Option.for(value: 222, label: "Member")] }
  let(:channels) { [] }
  let(:context) { Components::Lfg::PingableRoleFormContext.new(role_options:, channels:) }

  it "renders the section label and help" do
    expect(html).to include("Pingable roles")
    expect(html).to include("Only configured roles appear in the command")
  end

  it "renders the add button wired to the Stimulus controller" do
    expect(html).to include('data-action="pingable-roles#add"')
    expect(html).to include("Add role")
  end

  it "renders a template card for new entries" do
    expect(html).to include("<template")
    expect(html).to include('data-pingable-roles-target="template"')
  end

  context "when a pingable role is configured" do
    before { create(:lfg_pingable_role, lfg_settings: settings, role_id: 222) }

    it "renders a card for the existing role" do
      expect(html).to include(">Member<")
    end
  end
end
