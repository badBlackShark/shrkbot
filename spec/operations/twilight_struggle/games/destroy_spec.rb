# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Games::Destroy do
  subject(:result) { described_class.call(game:) }

  let!(:game) { create(:twilight_struggle_game) }

  it "destroys the row" do
    result
    expect(TwilightStruggle::Game.find_by(id: game.id)).to be_nil
  end

  it "returns success" do
    expect(result).to be_success
  end
end
