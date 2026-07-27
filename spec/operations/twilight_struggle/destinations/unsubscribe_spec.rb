# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Destinations::Unsubscribe do
  subject(:result) { described_class.call(destination:) }

  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, template_win: "kept") }

  it "succeeds" do
    expect(result).to be_success
  end

  it "unsubscribes the server" do
    result
    expect(destination.reload).not_to be_active
  end

  it "keeps the row, so the wording survives to be subscribed to again" do
    result
    expect(destination.reload.template_win).to eq("kept")
  end

  context "when the server already posted a result for this tournament" do
    let(:game) { create(:twilight_struggle_game, tournament:) }
    let!(:posted_message) { create(:twilight_struggle_posted_message, game:, server_configuration:) }

    it "leaves the posted message alone" do
      result
      expect(TwilightStruggle::PostedMessage.find_by(id: posted_message.id)).to be_present
    end
  end

  context "when the server never subscribed in the first place" do
    let(:destination) { server_configuration.twilight_struggle_destinations.new(tournament:) }

    it "succeeds without creating a row" do
      expect { result }.not_to change(TwilightStruggle::Destination, :count)
      expect(result).to be_success
    end
  end
end
