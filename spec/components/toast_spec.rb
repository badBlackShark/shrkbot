# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Toast do
  subject(:html) { described_class.new(level:, message: "Saved.").call }

  context "with the warning level" do
    let(:level) { "warning" }

    it "renders the warning icon and tone" do
      expect(html).to include("bg-warning-solid").and include("text-warning-text")
    end

    it "stays until dismissed" do
      expect(html).to include('data-toast-sticky-value="true"')
    end
  end

  context "with any level" do
    let(:level) { "notice" }

    it "stays out of Turbo's page cache, so Back never replays it" do
      expect(html).to include("data-turbo-temporary")
    end
  end

  context "with the notice level" do
    let(:level) { "notice" }

    it "renders the success tone and times out" do
      expect(html).to include("bg-success-solid")
      expect(html).not_to include("data-toast-sticky-value")
    end
  end
end
