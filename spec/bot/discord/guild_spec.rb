require "rails_helper"

RSpec.describe Discord::Guild do
  describe ".from_api" do
    subject(:guild) { described_class.from_api(payload) }

    let(:payload) do
      {
        "id" => "123",
        "name" => "Dev Refuge",
        "owner" => false,
        "permissions" => "32",
        "icon" => "abc"
      }
    end

    it "coerces the snowflake id to an integer" do
      expect(guild.id).to eq(123)
    end

    it "parses the permissions bitfield to an integer" do
      expect(guild.permissions).to eq(32)
    end
  end

  describe "#manageable?" do
    subject(:manageable) { guild.manageable? }

    let(:guild) { described_class.new(id: 1, name: "S", owner:, permissions:, icon: nil) }
    let(:owner) { false }
    let(:permissions) { 0 }

    context "when the user owns the server" do
      let(:owner) { true }

      it { is_expected.to be(true) }
    end

    context "with the ADMINISTRATOR permission" do
      let(:permissions) { 0x8 }

      it { is_expected.to be(true) }
    end

    context "with the MANAGE_GUILD permission" do
      let(:permissions) { 0x20 }

      it { is_expected.to be(true) }
    end

    context "with neither ownership nor a managing permission" do
      let(:permissions) { 0x400 }

      it { is_expected.to be(false) }
    end
  end
end
