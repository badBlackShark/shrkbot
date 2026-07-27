# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Tournaments::Upsert do
  subject(:result) do
    described_class.call(
      external_id:,
      name:,
      parent:,
      status:,
      admins:
    )
  end

  let(:external_id) { "ext-1" }
  let(:name) { "Online Twilight Struggle League" }
  let(:parent) { nil }
  let(:status) { nil }
  let(:admins) { nil }

  it "creates a tournament when none exists" do
    expect { result }.to change(TwilightStruggle::Tournament, :count).by(1)
  end

  it "returns success" do
    expect(result).to be_success
  end

  context "when a tournament with the external_id already exists" do
    let!(:existing) { create(:twilight_struggle_tournament, external_id:, name: "Old Name") }
    let(:name) { "New Name" }

    it "updates the row in place" do
      expect { result }.not_to change(TwilightStruggle::Tournament, :count)
      expect(existing.reload.name).to eq("New Name")
    end
  end

  context "with a parent and status" do
    let(:parent) { create(:twilight_struggle_tournament) }
    let(:status) { "open" }

    it "sets the parent and status" do
      expect(result.value.parent).to eq(parent)
      expect(result.value.status).to eq(status)
    end
  end

  context "with a blank name" do
    let(:name) { "" }

    it "returns failure with errors" do
      expect(result).to be_failure
      expect(result.errors).to be_present
    end
  end

  describe "admin replacement" do
    let!(:existing) { create(:twilight_struggle_tournament, external_id:, name: "Old Name") }
    let!(:existing_admin) { create(:twilight_struggle_tournament_admin, tournament: existing) }

    context "when admins is not passed" do
      it "leaves existing admin rows untouched" do
        expect { result }.not_to change(TwilightStruggle::TournamentAdmin, :count)
        expect(TwilightStruggle::TournamentAdmin.exists?(existing_admin.id)).to be(true)
      end
    end

    context "when admins is an empty array" do
      let(:admins) { [] }

      it "deletes all admin rows for that tournament" do
        result
        expect(existing.admins).to be_empty
      end
    end

    context "when admins is a list of digit strings" do
      let(:admins) { ["111111111111111111", "222222222222222222"] }

      it "creates the admin rows" do
        result
        expect(existing.admins.pluck(:discord_id)).to contain_exactly(111111111111111111, 222222222222222222)
      end
    end

    context "when admins replaces a previous list" do
      let(:admins) { [existing_admin.discord_id.to_s, "333333333333333333"] }

      it "drops admins no longer present" do
        result
        expect(existing.admins.pluck(:discord_id)).to contain_exactly(existing_admin.discord_id, 333333333333333333)
      end

      it "keeps the surviving admin's row without recreating it" do
        expect { result }.not_to change { existing_admin.reload.id }
      end
    end

    context "when admins has duplicate ids in the payload" do
      let(:admins) { ["444444444444444444", "444444444444444444"] }

      it "creates a single row" do
        result
        expect(existing.admins.pluck(:discord_id)).to contain_exactly(444444444444444444)
      end
    end
  end
end
