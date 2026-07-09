# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::OverviewForm do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let(:context) do
    instance_double(
      Moderation::OverviewContext,
      staff_role_id: nil,
      staff_role_present?: false,
      permission_warning?: false,
      sub_plugin_rows: []
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

  it "renders no enable_error callout by default" do
    expect(html).not_to include("Something went wrong enabling.")
  end

  it "renders the matching explainer with dropdown-menu class and menu target" do
    expect(html).to include("dropdown-menu")
    expect(html).to include('data-dropdown-target="menu"')
  end

  context "with an enable_error" do
    subject(:html) do
      described_class.new(
        server_configuration: config,
        context:,
        enable_error: "Something went wrong enabling."
      ).render_in(view_context)
    end

    it "renders the error callout" do
      expect(html).to include("Something went wrong enabling.")
    end
  end
end
