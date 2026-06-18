require "rails_helper"

RSpec.describe Ops::Roles::DeleteSet do
  subject(:result) { described_class.call(role_set: set) }

  let(:set) { create(:role_set) }

  before do
    create(:assignable_role, role_set: set)
  end

  it "destroys the set and cascades to its roles" do
    expect { result }
      .to change(Roles::Set, :count).by(-1)
      .and change(Roles::AssignableRole, :count).by(-1)
  end
end
