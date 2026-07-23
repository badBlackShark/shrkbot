# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::SetupGuideCard do
  subject(:html) { described_class.new.render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }

  it "renders the non-mentionable recommendation" do
    expect(html).to include("Make your LFG roles non-mentionable")
    expect(html).to include("Allow anyone to @mention this role")
  end

  it "renders the visibility recommendation" do
    expect(html).to include("Restrict who can run /lfg")
    expect(html).to include("limit the /lfg command")
  end
end
