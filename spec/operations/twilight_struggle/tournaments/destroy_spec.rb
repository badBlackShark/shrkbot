# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Tournaments::Destroy do
  subject(:result) { described_class.call(tournament:) }

  let!(:tournament) { create(:twilight_struggle_tournament) }

  it "destroys the row" do
    result
    expect(TwilightStruggle::Tournament.find_by(id: tournament.id)).to be_nil
  end

  it "returns success" do
    expect(result).to be_success
  end
end
