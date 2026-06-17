require "rails_helper"

RSpec.describe Setting do
  describe "primary key" do
    subject(:id) { setting.id }

    let(:setting) { create(:setting, key: "x", value: "y") }

    it "generates a prefixed-uuid" do
      expect(id).to match(/\Aset_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
  end

  describe "key uniqueness" do
    subject(:validation) { build(:setting, key: "dupe") }

    before { create(:setting, key: "dupe") }

    it "enforces unique keys" do
      expect(validation).not_to be_valid
    end
  end

  describe ".get/.set" do
    context "setting a fresh key" do
      before { Setting.set("greeting", "hi") }

      it "round-trips the value through .get" do
        expect(Setting.get("greeting")).to eq("hi")
      end
    end

    context "setting an existing key again" do
      before do
        Setting.set("greeting", "hi")
        Setting.set("greeting", "yo")
      end

      it "overwrites the value" do
        expect(Setting.get("greeting")).to eq("yo")
      end

      it "upserts rather than inserting a second row" do
        expect(Setting.where(key: "greeting").count).to eq(1)
      end
    end

    context "getting an unset key" do
      subject(:value) { Setting.get("missing") }

      it "returns nil" do
        expect(value).to be_nil
      end
    end
  end

  describe ".owner_error_dms" do
    context "when unset" do
      subject(:result) { Setting.owner_error_dms? }

      it "defaults to false" do
        expect(result).to be(false)
      end
    end

    context "round-tripping a boolean" do
      before do
        Setting.owner_error_dms = true
      end

      it "stores and retrieves true" do
        expect(Setting.owner_error_dms?).to be(true)
      end

      it "round-trips false" do
        Setting.owner_error_dms = false
        expect(Setting.owner_error_dms?).to be(false)
      end
    end
  end
end
