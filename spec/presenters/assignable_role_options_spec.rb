# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignableRoleOptions do
  subject(:options) { described_class.new(config).options }

  let(:config) { create(:server_configuration, discord_id: 900, bot_role_position: 5) }

  before do
    create(:server_role, server_configuration: config, discord_id: 900, name: "everyone", position: 0)
    create(:server_role, server_configuration: config, discord_id: 10, name: "Member", position: 2, color: 0x37a79e)
    create(:server_role, server_configuration: config, discord_id: 11, name: "Admin", position: 8)
    create(:server_role, server_configuration: config, discord_id: 12, name: "Booster", position: 1, managed: true)
  end

  it "excludes the @everyone role whose id matches the guild" do
    expect(options.map(&:label)).not_to include("everyone")
  end

  it "orders roles from highest to lowest" do
    expect(options.map(&:label)).to eq(["Admin", "Member", "Booster"])
  end

  it "renders the stored colour as a hex string" do
    member = options.find { |option| option.label == "Member" }
    expect(member.color).to eq("#37a79e")
  end

  it "falls back to a neutral colour when the role has none" do
    admin = options.find { |option| option.label == "Admin" }
    expect(admin.color).to eq(described_class::DEFAULT_COLOR)
  end

  it "disables roles ranked at or above shrkbot with a reason" do
    admin = options.find { |option| option.label == "Admin" }
    expect(admin).to have_attributes(disabled: true, reason: I18n.t("assignable_roles.above_bot"))
  end

  it "disables Discord-managed roles with a reason" do
    booster = options.find { |option| option.label == "Booster" }
    expect(booster).to have_attributes(disabled: true, reason: I18n.t("assignable_roles.managed"))
  end

  it "leaves assignable roles enabled" do
    member = options.find { |option| option.label == "Member" }
    expect(member).to have_attributes(disabled: false, reason: nil)
  end

  it "reports when any role is unassignable" do
    expect(described_class.new(config).any_unassignable?).to be(true)
  end

  context "when the bot's role position hasn't synced yet" do
    let(:config) { create(:server_configuration, discord_id: 900, bot_role_position: nil) }

    it "greys managed roles but not by position" do
      admin = options.find { |option| option.label == "Admin" }
      booster = options.find { |option| option.label == "Booster" }
      expect(admin.disabled).to be(false)
      expect(booster.disabled).to be(true)
    end
  end
end
