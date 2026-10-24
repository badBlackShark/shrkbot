# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Templates do
  let(:patch_notes) { "Integrations::Steam::PatchNotesPublished" }

  describe "DEFAULTS" do
    it "has a template for exactly the subscribable event types" do
      expect(described_class::DEFAULTS.keys).to match_array(Feeds::EVENT_TYPES)
    end
  end

  describe ".custom" do
    subject(:custom) { described_class.custom(patch_notes, text) }

    context "with text of its own" do
      let(:text) { "  Patch day: {title}  " }

      it { is_expected.to eq("Patch day: {title}") }
    end

    ["", "  ", nil].each do |blank|
      context "with #{blank.inspect}" do
        let(:text) { blank }

        it { is_expected.to be_nil }
      end
    end

    context "with the default text" do
      let(:text) { described_class.default(patch_notes) }

      it { is_expected.to be_nil }
    end

    context "with the default text and surrounding whitespace" do
      let(:text) { "  #{described_class.default(patch_notes)}\n" }

      it { is_expected.to be_nil }
    end
  end

  describe ".renders_empty?" do
    subject(:renders_empty) { described_class.renders_empty?(template, role_id:) }

    let(:role_id) { nil }

    {
      "{role}" => true,
      "{author}" => true,
      "  {role} {author} " => true,
      "{title}" => false,
      "New patch!" => false,
      "{unknown}" => false
    }.each do |text, empty|
      context "with #{text.inspect} and no role" do
        let(:template) { text }

        it { is_expected.to be(empty) }
      end
    end

    context "with {role} and a role to ping" do
      let(:template) { "{role}" }
      let(:role_id) { 1 }

      it { is_expected.to be(false) }
    end
  end
end
