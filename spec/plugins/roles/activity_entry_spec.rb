# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::ActivityEntry do
  subject(:entry) { described_class.build(set:, actor: "<@42>", gained:, lost:) }

  let(:set) { create(:role_set, name: "Pronouns") }
  let(:gained) { ["Gamer"] }
  let(:lost) { [] }

  it "titles the entry" do
    expect(entry[:title]).to eq("Roles updated")
  end

  it "names the source menu in the meta line" do
    expect(entry[:meta]).to eq('Self-assigned via the "Pronouns" role menu')
  end

  context "with gained roles only" do
    let(:gained) { ["Gamer", "Artist"] }

    it "renders a gained sentence with bold role names" do
      expect(entry[:body]).to eq("<@42> gained **Gamer** and **Artist**.")
    end
  end

  context "with lost roles only" do
    let(:gained) { [] }
    let(:lost) { ["Viewer"] }

    it "renders a lost sentence" do
      expect(entry[:body]).to eq("<@42> lost **Viewer**.")
    end
  end

  context "with roles gained and lost in one interaction" do
    let(:lost) { ["Viewer"] }

    it "renders one combined sentence" do
      expect(entry[:body]).to eq("<@42> gained **Gamer** and lost **Viewer**.")
    end
  end
end
