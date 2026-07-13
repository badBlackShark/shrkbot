# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::PunishmentNote do
  subject(:line) { described_class.line(punishment, timeout_until:) }

  let(:timeout_until) { nil }

  context "when the punishment is a timeout" do
    let(:punishment) { "timeout" }
    let(:timeout_until) { Time.at(1_700_000_000) }

    it "renders an absolute Discord timestamp" do
      expect(line).to eq("User was timed out until <t:1700000000:f>.")
    end
  end

  context "when the member was kicked" do
    let(:punishment) { "kick" }

    it "states the kick" do
      expect(line).to eq("User was kicked.")
    end
  end

  context "when the member was banned" do
    let(:punishment) { "ban" }

    it "states the ban" do
      expect(line).to eq("User was banned.")
    end
  end

  context "when there is no punishment" do
    let(:punishment) { "none" }

    it "states that no further action was taken" do
      expect(line).to eq("No further action was taken.")
    end
  end
end
