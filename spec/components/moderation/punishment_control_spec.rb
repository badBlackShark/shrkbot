# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::PunishmentControl do
  include_context "component view context"

  subject(:html) do
    described_class.new(
      name: "spam_protection[punishment]",
      value: "none",
      timeout_seconds: 3600
    ).render_in(view_context)
  end

  it "renders the punishment segmented control with None/Time out/Kick/Ban options" do
    expect(html).to include("None")
    expect(html).to include("Time out")
    expect(html).to include("Kick")
    expect(html).to include("Ban")
  end

  it "renders the hidden punishment input with the correct name" do
    expect(html).to include('name="spam_protection[punishment]"')
  end

  it "wires the Stimulus punishment controller" do
    expect(html).to include('data-controller="punishment"')
  end

  it "renders the duration select with the derived timeout_seconds field name" do
    expect(html).to include('name="spam_protection[timeout_seconds]"')
  end

  it "renders the duration block hidden when value is not timeout" do
    expect(html).to include('data-punishment-target="duration"')
    expect(html).to include("hidden")
  end

  it "renders the ban warning block hidden when value is not ban" do
    expect(html).to include('data-punishment-target="banWarning"')
  end

  it "renders the ban warning copy" do
    expect(html).to include("A ban is permanent")
  end

  context "when value is timeout" do
    subject(:html) do
      described_class.new(
        name: "spam_protection[punishment]",
        value: "timeout",
        timeout_seconds: 3600
      ).render_in(view_context)
    end

    it "does not hide the duration block" do
      expect(html).not_to include('data-punishment-target="duration" hidden')
    end
  end

  context "when used for image scanning" do
    subject(:html) do
      described_class.new(
        name: "image_scanning[punishment]",
        value: "none",
        timeout_seconds: 3600
      ).render_in(view_context)
    end

    it "uses the correct timeout field name for the sub-plugin" do
      expect(html).to include('name="image_scanning[timeout_seconds]"')
    end
  end

  context "when used for the confirmed-scam tier" do
    subject(:html) do
      described_class.new(
        name: "image_scanning[confirmed_punishment]",
        value: "none",
        timeout_seconds: 3600
      ).render_in(view_context)
    end

    it "derives the confirmed timeout field name" do
      expect(html).to include('name="image_scanning[confirmed_timeout_seconds]"')
    end

    context "with a custom none_label" do
      subject(:html) do
        described_class.new(
          name: "image_scanning[confirmed_punishment]",
          value: "none",
          timeout_seconds: 3600,
          none_label: "Same as above"
        ).render_in(view_context)
      end

      it "renders the override label in place of None" do
        expect(html).to include("Same as above")
        expect(html).not_to include(">None<")
      end
    end
  end
end
