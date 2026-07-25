# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Tournaments::Claim do
  subject(:result) { described_class.call(tournament:, server_configuration:) }

  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) { create(:twilight_struggle_tournament) }

  context "when the tournament is unclaimed" do
    it "succeeds" do
      expect(result).to be_success
    end

    it "points the tournament at the server" do
      result
      expect(tournament.reload.server_configuration).to eq(server_configuration)
    end
  end

  context "when another server already claimed it" do
    let(:other_server) { create(:server_configuration) }
    let(:tournament) { create(:twilight_struggle_tournament, server_configuration: other_server) }

    it "fails" do
      expect(result).to be_failure
    end

    it "leaves the existing claim alone" do
      result
      expect(tournament.reload.server_configuration).to eq(other_server)
    end
  end
end
