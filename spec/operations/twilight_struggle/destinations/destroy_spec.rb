# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Destinations::Destroy do
  subject(:result) { described_class.call(destination:) }

  let!(:destination) { create(:twilight_struggle_destination) }

  it "destroys the destination" do
    result
    expect(TwilightStruggle::Destination.find_by(id: destination.id)).to be_nil
  end

  it "returns success" do
    expect(result).to be_success
  end

  context "when the server has an already-posted message for this tournament's games" do
    let(:tournament) { destination.tournament }
    let(:server_configuration) { destination.server_configuration }
    let(:game) { create(:twilight_struggle_game, tournament:) }
    let!(:posted_message) { create(:twilight_struggle_posted_message, game:, server_configuration:) }

    it "leaves the posted message row alone" do
      result
      expect(TwilightStruggle::PostedMessage.find_by(id: posted_message.id)).to be_present
    end
  end
end
