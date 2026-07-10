# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChannelOverwrite do
  describe "primary key" do
    subject(:id) { create(:channel_overwrite).id }

    it "generates a prefixed-uuid" do
      expect(id).to match(/\Acov_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
  end

  describe "target_type" do
    subject(:overwrite) { build(:channel_overwrite, target_type:) }

    context "with an unknown target_type" do
      let(:target_type) { "everyone" }

      it { is_expected.not_to be_valid }
    end

    context "with member" do
      let(:target_type) { "member" }

      it { is_expected.to be_valid }
    end

    context "with role" do
      let(:target_type) { "role" }

      it "returns true for role?" do
        expect(overwrite.role?).to be(true)
      end
    end
  end

  describe "target_id uniqueness" do
    subject(:duplicate) { build(:channel_overwrite, server_channel: channel, target_id: 999) }

    let(:channel) { create(:server_channel) }

    before do
      create(:channel_overwrite, server_channel: channel, target_id: 999)
    end

    it "forbids the same target twice on one channel" do
      expect(duplicate).not_to be_valid
    end
  end
end
