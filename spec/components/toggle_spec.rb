# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Toggle do
  context "as a field inside another form (no instant submit)" do
    subject(:html) { Components::Toggle.new(name: "welcome_setting[enabled]", checked: true, label: "Enable welcomes").call }

    it "renders just the switch, with no form of its own" do
      expect(html).not_to include("<form")
      expect(html).to include('name="welcome_setting[enabled]"')
      expect(html).to include('aria-label="Enable welcomes"')
    end

    it "includes a checked checkbox and the unchecked fallback" do
      expect(html).to include('type="checkbox"').and include("checked")
      expect(html).to include('type="hidden"').and include('value="0"')
    end

    it "does not wire up auto-submit" do
      expect(html).not_to include("change->toggle#submit")
    end

    it "uses the standard track size by default" do
      expect(html).to include("w-11").and include("after:size-5")
    end
  end

  context "as a nameless control (a toggle-all that drives other fields, not a field itself)" do
    subject(:html) { Components::Toggle.new(checked: false, label: "Toggle all Roles events").call }

    it "renders no name attribute and no hidden fallback, so it never posts a stray param" do
      expect(html).not_to include("name=")
      expect(html).not_to include('type="hidden"')
      expect(html).to include('aria-label="Toggle all Roles events"')
    end
  end

  context "at the mini size" do
    subject(:html) { Components::Toggle.new(name: "logging[all][roles]", checked: false, label: "Toggle all Roles events", size: :mini).call }

    it "renders the smaller track and knob" do
      expect(html).to include("w-8").and include("after:size-3.5")
      expect(html).not_to include("w-11")
    end
  end
end
