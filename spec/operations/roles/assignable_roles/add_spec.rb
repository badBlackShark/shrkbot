require "rails_helper"

RSpec.describe Ops::Roles::AssignableRoles::Add do
  subject(:result) { described_class.call(role_set: set, role_id: 42) }

  let(:set) { create(:role_set) }

  it "adds the role at the first position" do
    expect(result.success?).to be(true)
    expect(result.value).to have_attributes(role_id: 42, position: 0)
  end

  context "when a role already exists" do
    before do
      create(:assignable_role, role_set: set, position: 0)
    end

    it "appends after the last position" do
      expect(result.value.position).to eq(1)
    end
  end
end
