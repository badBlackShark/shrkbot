# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::RoleSelect do
  subject(:html) do
    described_class.new(
      name: "roles[role_sets][0][role_ids][]",
      options: [
        Components::TomSelect::Option.for(value: 10, label: "Member", color: "#37a79e"),
        Components::TomSelect::Option.for(value: 11, label: "Admin", disabled: true, reason: "Above shrkbot.")
      ],
      selected: [10],
      placeholder: "Choose roles"
    ).call
  end

  it "renders a multi-select wired for colour dots" do
    expect(html).to include("multiple")
    expect(html).to include("data-tom-select-color-dots-value")
  end

  it "marks the already-assigned roles selected" do
    expect(html).to include('value="10"').and include("selected")
  end

  it "carries each role's colour and disabled reason for the dropdown render" do
    expect(html).to include("#37a79e")
    expect(html).to include("Above shrkbot.")
    expect(html).to include('value="11"').and include("disabled")
  end
end
