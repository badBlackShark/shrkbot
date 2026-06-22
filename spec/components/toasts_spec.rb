require "rails_helper"

RSpec.describe Components::Toasts do
  subject(:html) { described_class.new(flash: flash).call }

  context "with a notice" do
    let(:flash) { {"notice" => "Signed in as shrk."} }

    it "renders the message" do
      expect(html).to include("Signed in as shrk.")
    end

    it "wires the auto-dismiss controller" do
      expect(html).to include('data-controller="toast"')
    end
  end

  context "with an alert" do
    let(:flash) { {"alert" => "Please sign in to continue."} }

    it "renders the message" do
      expect(html).to include("Please sign in to continue.")
    end
  end

  context "with no flash" do
    let(:flash) { {} }

    it "renders nothing" do
      expect(html.to_s.strip).to be_empty
    end
  end
end
