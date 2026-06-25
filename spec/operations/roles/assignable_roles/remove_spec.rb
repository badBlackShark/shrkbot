# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Roles::AssignableRoles::Remove do
  subject(:result) { described_class.call(assignable_role: role) }

  let!(:role) { create(:assignable_role) }

  it "removes the role" do
    expect { result }.to change(Roles::AssignableRole, :count).by(-1)
  end
end
