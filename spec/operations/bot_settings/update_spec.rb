# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::BotSettings::Update do
  subject(:result) { described_class.call(owner_error_dms:) }

  context "when given a truthy checkbox value" do
    let(:owner_error_dms) { "1" }

    it "sets the flag to true and returns true" do
      expect(result.value).to be(true)
      expect(BotSetting.owner_error_dms?).to be(true)
    end
  end

  context "when given a falsy checkbox value" do
    let(:owner_error_dms) { "0" }

    before do
      BotSetting.owner_error_dms = true
    end

    it "sets the flag to false and returns false" do
      expect(result.value).to be(false)
      expect(BotSetting.owner_error_dms?).to be(false)
    end
  end
end
