# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::SubscriptionList do
  subject(:rows) { described_class.new(server_configuration:, archived:, tournaments:).rows }

  let(:server_configuration) { create(:server_configuration) }
  let(:archived) { false }
  let(:tournaments) { TwilightStruggle::Tournament.all }

  let!(:subscribed) { create(:twilight_struggle_tournament, name: "OTSL 2026") }
  let!(:destination) { create(:twilight_struggle_destination, tournament: subscribed, server_configuration:) }
  let!(:unsubscribed) { create(:twilight_struggle_tournament, name: "RATS Cup 2026") }

  it "pairs a subscribed tournament with this server's destination" do
    expect(rows).to include([subscribed, destination])
  end

  it "pairs an unsubscribed tournament with nil" do
    expect(rows).to include([unsubscribed, nil])
  end

  it "does not leak another server's destination for the same tournament" do
    other_server = create(:server_configuration)
    other_destination = create(:twilight_struggle_destination, tournament: unsubscribed, server_configuration: other_server)

    expect(rows).to include([unsubscribed, nil])
    expect(rows.flatten).not_to include(other_destination)
  end

  context "when this server manually archived its destination" do
    let!(:destination) { create(:twilight_struggle_destination, tournament: subscribed, server_configuration:, archived_at: 1.day.ago) }

    it "excludes it from the active rows" do
      expect(rows.map(&:first)).not_to include(subscribed)
    end

    context "on the archived tab" do
      let(:archived) { true }

      it "includes it" do
        expect(rows.map(&:first)).to include(subscribed)
      end
    end
  end

  context "when tournaments is narrowed to one tournament" do
    let(:tournaments) { TwilightStruggle::Tournament.where(id: subscribed.id) }

    it "only contains that tournament" do
      expect(rows.map(&:first)).to contain_exactly(subscribed)
    end
  end

  context "when tournaments is left at its default" do
    subject(:rows) { described_class.new(server_configuration:, archived:).rows }

    it "returns all of them" do
      expect(rows.map(&:first)).to contain_exactly(subscribed, unsubscribed)
    end
  end

  context "when a tournament is closed upstream" do
    let!(:unsubscribed) { create(:twilight_struggle_tournament, name: "Done cup", status: "closed") }

    it "excludes it from the active rows" do
      expect(rows.map(&:first)).not_to include(unsubscribed)
    end

    context "on the archived tab" do
      let(:archived) { true }

      it "includes it" do
        expect(rows.map(&:first)).to include(unsubscribed)
      end
    end
  end
end
