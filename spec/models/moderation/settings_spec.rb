# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Settings do
  subject(:settings) { build(:moderation_settings) }

  it "belongs to a server configuration" do
    expect(settings.server_configuration).to be_present
  end

  it "uses the correct table name" do
    expect(described_class.table_name).to eq("moderation_settings")
  end

  it "persists via the factory" do
    expect { create(:moderation_settings) }.to change(described_class, :count).by(1)
  end

  describe "new_account_age_days validation" do
    subject(:settings) { build(:moderation_settings, new_account_age_days:) }

    context "at the lower bound" do
      let(:new_account_age_days) { 1 }

      it { is_expected.to be_valid }
    end

    context "at the default" do
      let(:new_account_age_days) { 30 }

      it { is_expected.to be_valid }
    end

    context "at the upper bound" do
      let(:new_account_age_days) { 365 }

      it { is_expected.to be_valid }
    end

    context "below the lower bound" do
      let(:new_account_age_days) { 0 }

      it "is invalid with an error on the field" do
        expect(settings).not_to be_valid
        expect(settings.errors[:new_account_age_days]).to be_present
      end
    end

    context "above the upper bound" do
      let(:new_account_age_days) { 366 }

      it "is invalid with an error on the field" do
        expect(settings).not_to be_valid
        expect(settings.errors[:new_account_age_days]).to be_present
      end
    end
  end
end
