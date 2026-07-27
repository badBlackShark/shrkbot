# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Destinations::Subscribe do
  subject(:result) { described_class.call(destination:) }

  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, active: false, template_win: "kept") }

  it "succeeds" do
    expect(result).to be_success
  end

  it "subscribes the server" do
    result
    expect(destination.reload).to be_active
  end

  it "brings the wording it was unsubscribed with back with it" do
    result
    expect(destination.reload.template_win).to eq("kept")
  end

  context "when the server has never subscribed to this tournament" do
    let(:destination) { server_configuration.twilight_struggle_destinations.new(tournament:) }

    it "creates the destination" do
      expect { result }.to change(TwilightStruggle::Destination, :count).by(1)
      expect(destination.reload).to be_active
    end
  end
end
