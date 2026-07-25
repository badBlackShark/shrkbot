# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Destinations::Create do
  subject(:result) { described_class.call(server_configuration:, tournament:) }

  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }

  it "creates a destination" do
    expect { result }.to change(TwilightStruggle::Destination, :count).by(1)
  end

  it "returns the destination" do
    expect(result.value).to be_a(TwilightStruggle::Destination)
    expect(result.value.tournament).to eq(tournament)
    expect(result.value.server_configuration).to eq(server_configuration)
  end

  it "succeeds" do
    expect(result).to be_success
  end

  context "when this server already subscribes to this tournament" do
    let!(:existing) { create(:twilight_struggle_destination, tournament:, server_configuration:) }

    it "fails" do
      expect(result).to be_failure
    end

    it "does not create a second destination" do
      expect { result }.not_to change(TwilightStruggle::Destination, :count)
    end
  end
end
