# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Tournaments::Upsert do
  subject(:result) do
    described_class.call(
      external_id:,
      name:,
      parent:,
      status:
    )
  end

  let(:external_id) { "ext-1" }
  let(:name) { "Ameritash 2026" }
  let(:parent) { nil }
  let(:status) { nil }

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
end
