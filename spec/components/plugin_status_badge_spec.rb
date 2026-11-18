# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PluginStatusBadge do
  include_context "component view context"

  subject(:html) { described_class.new(configured:, locked:).render_in(view_context) }

  let(:configured) { true }
  let(:locked) { false }

  it "renders nothing for a configured plugin" do
    expect(html).to be_empty
  end

  context "when the plugin needs setup" do
    let(:configured) { false }

    it "says so" do
      expect(html).to include("Needs setup")
    end
  end

  context "when the plugin is always on" do
    let(:configured) { false }
    let(:locked) { true }

    it "says always on, even before setup" do
      expect(html).to include("Always on")
      expect(html).not_to include("Needs setup")
    end
  end
end
