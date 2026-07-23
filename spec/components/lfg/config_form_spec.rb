# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::ConfigForm do
  subject(:html) do
    described_class.new(server_configuration: config, enable_error:).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:config) { create(:server_configuration) }
  let(:enable_error) { nil }

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
    expect(html).to include("Make your LFG roles non-mentionable")
    expect(html).to include("Restrict who can run /lfg")
  end

  context "when enable_error is given" do
    let(:enable_error) { "Something went wrong." }

    it "renders a danger callout with the message" do
      expect(html).to include("Something went wrong.")
    end
  end

  context "when enable_error is nil" do
    it "omits the callout" do
      expect(html).not_to include("Something went wrong.")
    end
  end
end
