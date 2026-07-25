# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::Destination do
  subject(:destination) { build(:twilight_struggle_destination) }

  it "is valid from the factory" do
    expect(destination).to be_valid
  end

  describe "uniqueness" do
    let!(:existing) { create(:twilight_struggle_destination) }

    it "rejects a second destination for the same tournament and server" do
      duplicate = build(
        :twilight_struggle_destination,
        tournament: existing.tournament,
        server_configuration: existing.server_configuration
      )

      expect(duplicate).not_to be_valid
    end

    it "allows the same tournament for a different server" do
      duplicate = build(:twilight_struggle_destination, tournament: existing.tournament)

      expect(duplicate).to be_valid
    end

    it "allows the same server for a different tournament" do
      duplicate = build(:twilight_struggle_destination, server_configuration: existing.server_configuration)

      expect(duplicate).to be_valid
    end
  end

  describe "#manually_archived?" do
    it "is true when archived_at is set" do
      destination.archived_at = Time.current

      expect(destination.manually_archived?).to be(true)
    end

    it "is false when archived_at is nil" do
      destination.archived_at = nil

      expect(destination.manually_archived?).to be(false)
    end
  end
end
