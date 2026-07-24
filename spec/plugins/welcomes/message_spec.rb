# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::Message do
  subject(:rendered) { described_class.render(template, user:, username:, displayname:, member_count:) }

  let(:template) { "Welcome {user}! You are member {membercount}." }
  let(:user) { "<@1>" }
  let(:username) { "newmember" }
  let(:displayname) { "New Member" }
  let(:member_count) { 42 }

  it "substitutes {user} and {membercount}" do
    expect(rendered).to eq("Welcome <@1>! You are member 42.")
  end

  context "with the name placeholders" do
    let(:template) { "{username} joins as {displayname}" }

    it "substitutes {username} and {displayname}" do
      expect(rendered).to eq("newmember joins as New Member")
    end
  end

  context "with a placeholder repeated" do
    let(:template) { "{user} {user}" }
    let(:user) { "X" }

    it "replaces every occurrence" do
      expect(rendered).to eq("X X")
    end
  end

  context "with a backreference sequence in the substituted value" do
    let(:template) { "Hi {displayname}" }
    let(:displayname) { 'Sm\\0key' }

    it "inserts the value literally instead of expanding the sequence" do
      expect(rendered).to eq('Hi Sm\\0key')
    end
  end

  context "with a nil template" do
    let(:template) { nil }

    it "renders empty" do
      expect(rendered).to eq("")
    end
  end
end
