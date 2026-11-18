# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::EnableErrorCallout do
  subject(:html) { described_class.new(key: "welcomes", message:).call }

  let(:message) { nil }

  it "renders an empty target the page can hide" do
    expect(html).to eq('<div id="welcomes-enable-error" class="empty:hidden"></div>')
  end

  context "with a message" do
    let(:message) { "Welcomes needs a channel." }

    it "renders the message in a danger callout inside the target" do
      expect(html).to include('id="welcomes-enable-error"').and include("bg-danger-soft").and include("Welcomes needs a channel.")
    end
  end
end
