require "rails_helper"

RSpec.describe Roles::CustomId do
  let(:set) { double(id: "rst_abc123") }
  let(:role) { double(role_id: 42) }

  it "round-trips a manage id" do
    expect(described_class.parse(described_class.manage(set)))
      .to eq(action: :manage, set_id: "rst_abc123", role_id: nil)
  end

  it "round-trips a pick id carrying the role" do
    expect(described_class.parse(described_class.pick(set, role)))
      .to eq(action: :pick, set_id: "rst_abc123", role_id: 42)
  end

  it "round-trips a select id" do
    expect(described_class.parse(described_class.select(set)))
      .to eq(action: :select, set_id: "rst_abc123", role_id: nil)
  end

  it "yields a nil action for an id with no action segment" do
    expect(described_class.parse("roles")).to eq(action: nil, set_id: nil, role_id: nil)
  end
end
