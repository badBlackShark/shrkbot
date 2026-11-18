# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SaveErrorCallout do
  subject(:html) { described_class.new(key: "welcomes", message:).call }

  let(:message) { nil }

  it "renders an empty target the page can hide" do
    expect(html).to eq('<div id="welcomes-save-error" class="empty:hidden"></div>')
  end

  context "with a message" do
    let(:message) { "Welcomes needs a channel." }

    it "renders the message in a danger callout inside the target" do
      expect(html).to include('id="welcomes-save-error"').and include("bg-danger-soft").and include("Welcomes needs a channel.")
    end

    it "announces itself to screen readers when it replaces the empty target" do
      expect(html).to include('role="alert"')
    end
  end
end
