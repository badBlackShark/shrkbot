# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::ConfigForm do
  subject(:html) do
    described_class.new(server_configuration: config).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:config) { create(:server_configuration) }

  before do
    create(:lfg_settings, server_configuration: config)
  end

  it "renders the lfg-config root" do
    expect(html).to include('id="lfg-config"')
  end

  it "wires the pingable-roles Stimulus controller" do
    expect(html).to include('data-controller="pingable-roles"')
  end

  it "renders the setup guide recommendations" do
    expect(html).to include("Make your Looking for Game roles non-mentionable")
    expect(html).to include("Restrict who can run /lfg")
  end
end
