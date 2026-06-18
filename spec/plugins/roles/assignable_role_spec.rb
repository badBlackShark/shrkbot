require "rails_helper"

RSpec.describe Roles::AssignableRole do
  describe "primary key" do
    subject(:id) { create(:assignable_role).id }

    it "generates a prefixed-uuid" do
      expect(id).to match(/\Aasr_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
  end

  describe "role_id uniqueness" do
    subject(:duplicate) { build(:assignable_role, role_set: set, role_id: 555) }

    let(:set) { create(:role_set) }

    before do
      create(:assignable_role, role_set: set, role_id: 555)
    end

    it "forbids the same role twice in one set" do
      expect(duplicate).not_to be_valid
    end

    it "allows the same role in a different set" do
      expect(build(:assignable_role, role_id: 555)).to be_valid
    end
  end
end
