# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Roles::Sets::Update do
  subject(:result) do
    described_class.call(role_set: set, name: "New", selection_mode: "single", channel_override: 5)
  end

  let(:set) { create(:role_set, name: "Old", selection_mode: "multi", channel_override: nil) }

  it "updates the set" do
    result
    expect(set.reload).to have_attributes(name: "New", selection_mode: "single", channel_override: 5)
  end
end
