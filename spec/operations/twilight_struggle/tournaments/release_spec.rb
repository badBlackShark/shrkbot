# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Tournaments::Release do
  subject(:result) { described_class.call(tournament:) }

  let(:server_configuration) { create(:server_configuration) }
  let(:tournament) do
    create(:twilight_struggle_tournament, server_configuration:, discord_channel_id: "555", template_win: "kept")
  end

  it "succeeds" do
    expect(result).to be_success
  end

  it "drops the destination server" do
    result
    expect(tournament.reload.server_configuration).to be_nil
  end

  it "drops the channel, which is meaningless without its server" do
    result
    expect(tournament.reload.discord_channel_id).to be_nil
  end

  it "keeps the templates for whoever claims it next" do
    result
    expect(tournament.reload.template_win).to eq("kept")
  end
end
