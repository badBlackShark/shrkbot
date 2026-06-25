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
  end
end
