# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::Set do
  describe "primary key" do
    subject(:id) { create(:role_set).id }

    it "generates a prefixed-uuid" do
      expect(id).to match(/\Arst_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
  end

  describe "selection_mode" do
    subject(:set) { build(:role_set, selection_mode:) }

    context "with an unknown mode" do
      let(:selection_mode) { "exclusive" }

      it { is_expected.not_to be_valid }
    end

    context "with single" do
      let(:selection_mode) { "single" }

      it { is_expected.to be_valid }

      it "returns true for single?" do
        expect(set.single?).to be(true)
      end
    end
  end

  describe "#channel_id" do
    subject(:channel_id) { set.channel_id }

    let(:role_setting) { create(:role_setting, channel_id: 100) }

    context "without an override" do
      let(:set) { create(:role_set, role_setting:, channel_override: nil) }

      it "falls back to the plugin default channel" do
        expect(channel_id).to eq(100)
      end
    end

    context "with an override" do
      let(:set) { create(:role_set, role_setting:, channel_override: 200) }

      it "uses the override" do
        expect(channel_id).to eq(200)
      end
    end
  end

  describe "#assignable_roles" do
    subject(:destroy_set) { set.destroy }

    let(:set) { create(:role_set) }

    before do
      create(:assignable_role, role_set: set)
    end

    it "cascades deletion to its roles" do
      expect { destroy_set }.to change(Roles::AssignableRole, :count).by(-1)
    end
  end
end
