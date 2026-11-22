# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Source do
  let(:source) do
    Class.new(described_class) do
      def self.event_types
        %w[Integrations::Steam::PatchNotesPublished]
      end
    end
  end
  let(:subscription) { instance_double(Feeds::Subscription) }
  let(:event) { instance_double(Integrations::Event) }

  describe ".role_override_for" do
    it "is none, since a source has no per-type roles unless it says so" do
      expect(source.role_override_for(subscription, "Integrations::Steam::PatchNotesPublished")).to be_nil
    end
  end

  describe ".postable?" do
    it "lets every event post" do
      expect(source.postable?(subscription, event)).to be(true)
    end
  end

  describe ".post_type" do
    subject(:post_type) { source.post_type("Integrations::Steam::ArticlePublished") }

    it "counts every event as its own post type" do
      expect(post_type).to eq("Integrations::Steam::ArticlePublished")
    end
  end

  describe ".announced_types" do
    subject(:announced_types) { source.announced_types }

    it "announces exactly the followable types" do
      expect(announced_types).to eq(%w[Integrations::Steam::PatchNotesPublished])
    end
  end

  describe ".retract?" do
    subject(:retract) { source.retract?(subscription, event) }

    it "edits a post instead of deleting it" do
      expect(retract).to be(false)
    end
  end

  describe ".revive?" do
    subject(:revive) { source.revive?(subscription, event) }

    it "never sends a deleted post again" do
      expect(revive).to be(false)
    end
  end
  describe ".switched_away?" do
    subject(:switched_away) { source.switched_away?(subscription, event) }

    it "never hands a card over" do
      expect(switched_away).to be(false)
    end
  end
end
