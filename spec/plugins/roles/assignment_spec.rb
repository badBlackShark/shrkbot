# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::Assignment do
  describe ".single" do
    subject(:diff) { described_class.single(set_role_ids, picked) }

    let(:set_role_ids) { [1, 2, 3] }
    let(:picked) { 2 }

    it "adds the picked role" do
      expect(diff[:add]).to eq([2])
    end

    it "removes every other role in the set (exclusive selection)" do
      expect(diff[:remove]).to contain_exactly(1, 3)
    end
  end

  describe ".multi" do
    subject(:diff) { described_class.multi(set_role_ids, selected) }

    let(:set_role_ids) { [1, 2, 3] }

    context "with a subset selected" do
      let(:selected) { [1, 3] }

      it "adds the selected set roles" do
        expect(diff[:add]).to contain_exactly(1, 3)
      end

      it "removes the unselected set roles" do
        expect(diff[:remove]).to eq([2])
      end
    end

    context "when the selection includes ids outside the set" do
      let(:selected) { [1, 999] }

      it "ignores them" do
        expect(diff[:add]).to eq([1])
        expect(diff[:remove]).to contain_exactly(2, 3)
      end
    end

    context "with nothing selected" do
      let(:selected) { [] }

      it "removes the whole set" do
        expect(diff[:add]).to be_empty
        expect(diff[:remove]).to contain_exactly(1, 2, 3)
      end
    end
  end
end
