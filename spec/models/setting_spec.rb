require "rails_helper"

RSpec.describe Setting do
  it "generates a prefixed-uuid primary key" do
    setting = create(:setting, key: "x", value: "y")
    expect(setting.id).to match(/\Aset_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
  end

  it "enforces unique keys" do
    create(:setting, key: "dupe")
    expect(build(:setting, key: "dupe")).not_to be_valid
  end

  describe "get/set" do
    it "round-trips a value, upserting on the key" do
      Setting.set("greeting", "hi")
      expect(Setting.get("greeting")).to eq("hi")
      Setting.set("greeting", "yo")
      expect(Setting.get("greeting")).to eq("yo")
      expect(Setting.where(key: "greeting").count).to eq(1)
    end

    it "returns nil for an unset key" do
      expect(Setting.get("missing")).to be_nil
    end
  end

  describe "owner_error_dms" do
    it "defaults to false when unset" do
      expect(Setting.owner_error_dms?).to be(false)
    end

    it "round-trips a boolean through string storage" do
      Setting.owner_error_dms = true
      expect(Setting.owner_error_dms?).to be(true)
      Setting.owner_error_dms = false
      expect(Setting.owner_error_dms?).to be(false)
    end
  end
end
