# frozen_string_literal: true

require "rails_helper"

RSpec.describe Discord::Components do
  describe ".action_row" do
    subject(:row) { described_class.action_row([button]) }

    let(:button) { described_class.button(custom_id: "mod:confirm:abc", label: "Confirm scam") }

    it "wraps the components in an action row block" do
      expect(row).to eq(type: described_class::ACTION_ROW, components: [button])
    end
  end

  describe ".button" do
    subject(:button) do
      described_class.button(
        custom_id: "mod:dismiss:abc",
        label: "Dismiss",
        style: described_class::BUTTON_DANGER
      )
    end

    it "builds a button block carrying the style, label, and custom_id" do
      expect(button).to eq(
        type: described_class::BUTTON,
        style: described_class::BUTTON_DANGER,
        label: "Dismiss",
        custom_id: "mod:dismiss:abc"
      )
    end

    it "defaults to the primary style" do
      button = described_class.button(custom_id: "mod:confirm:abc", label: "Confirm scam")
      expect(button[:style]).to eq(1)
    end
  end
end
