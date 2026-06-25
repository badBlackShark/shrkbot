# frozen_string_literal: true

require "rails_helper"

RSpec.describe BotSetting do
  describe "primary key" do
    subject(:id) { setting.id }

    let(:setting) { create(:bot_setting, key: "x", value: "y") }

    it "generates a prefixed-uuid" do
      expect(id).to match(/\Abst_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
  end

  describe "key uniqueness" do
    subject(:validation) { build(:bot_setting, key: "dupe") }

    before do
      create(:bot_setting, key: "dupe")
    end

    it "enforces unique keys" do
      expect(validation).not_to be_valid
    end
  end

  describe ".get/.set" do
    context "setting a fresh key" do
      before do
        BotSetting.set("greeting", "hi")
      end

      it "round-trips the value through .get" do
        expect(BotSetting.get("greeting")).to eq("hi")
      end
    end

    context "setting an existing key again" do
      before do
        BotSetting.set("greeting", "hi")
        BotSetting.set("greeting", "yo")
      end

      it "overwrites the value" do
        expect(BotSetting.get("greeting")).to eq("yo")
      end

      it "upserts rather than inserting a second row" do
        expect(BotSetting.where(key: "greeting").count).to eq(1)
      end
    end

    context "getting an unset key" do
      subject(:value) { BotSetting.get("missing") }

      it "returns nil" do
        expect(value).to be_nil
      end
    end
  end

  describe ".owner_error_dms" do
    context "when unset" do
      subject(:result) { BotSetting.owner_error_dms? }

      it "defaults to false" do
        expect(result).to be(false)
      end
    end

    context "round-tripping a boolean" do
      before do
        BotSetting.owner_error_dms = true
      end

      it "stores and retrieves true" do
        expect(BotSetting.owner_error_dms?).to be(true)
      end

      it "round-trips false" do
        BotSetting.owner_error_dms = false
        expect(BotSetting.owner_error_dms?).to be(false)
      end
    end
  end
end
