# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::Denial do
  describe ".reason_text" do
    %i[
      bad_duration
      no_permission
      role_not_configured
    ].each do |reason|
      it "returns a non-empty string for #{reason}" do
        expect(described_class.reason_text(reason)).to be_a(String).and be_present
      end
    end

    it "interpolates days for too_new" do
      expect(described_class.reason_text(:too_new, 30)).to include("30")
    end

    it "interpolates a humanized time for cooldown" do
      expect(described_class.reason_text(:cooldown, 65)).to include("1m 5s")
    end

    it "humanizes a sub-minute cooldown without a minutes segment" do
      expect(described_class.reason_text(:cooldown, 5)).to include("5s")
    end

    it "renders channel mentions for channel_not_allowed" do
      text = described_class.reason_text(:channel_not_allowed, [20, 21])

      expect(text).to include("<#20>")
      expect(text).to include("<#21>")
    end

    it "renders role mentions for missing_required_role" do
      expect(described_class.reason_text(:missing_required_role, [55])).to include("<@&55>")
    end

    it "renders role mentions for missing_game_role" do
      expect(described_class.reason_text(:missing_game_role, [55])).to include("<@&55>")
    end

    it "renders role mentions for has_excluded_role" do
      expect(described_class.reason_text(:has_excluded_role, [55])).to include("<@&55>")
    end
  end

  describe ".entry" do
    subject(:entry) do
      described_class.entry(reason: :cooldown, detail: 65, actor_id: 1, role_id: 2, channel_name: "general")
    end

    it "returns a title, body, and meta" do
      expect(entry.keys).to contain_exactly(:title, :body, :meta)
    end

    it "mentions the actor and role in the body" do
      expect(entry[:body]).to include("<@1>")
      expect(entry[:body]).to include("<@&2>")
    end

    it "names the channel in the meta" do
      expect(entry[:meta]).to include("general")
    end
  end
end
