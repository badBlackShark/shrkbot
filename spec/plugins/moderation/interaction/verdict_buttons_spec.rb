# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Interaction::VerdictButtons do
  let(:phash_hex) { "deadbeefdeadbeef" }
  let!(:config) { create(:server_configuration) }

  describe ".build" do
    subject(:buttons) { described_class.build(server_configuration: config, phash_hex:) }

    context "when no Phash row exists for the hex" do
      it "returns confirm and dismiss buttons" do
        custom_ids = buttons.map { |b| b[:custom_id] }
        expect(custom_ids).to eq([
          "mod:confirm:#{phash_hex}",
          "mod:dismiss:#{phash_hex}"
        ])
      end
    end

    context "when a Phash exists but this guild has no confirmation" do
      before { create(:phash, phash: phash_hex) }

      it "returns confirm and dismiss buttons" do
        custom_ids = buttons.map { |b| b[:custom_id] }
        expect(custom_ids).to eq([
          "mod:confirm:#{phash_hex}",
          "mod:dismiss:#{phash_hex}"
        ])
      end
    end

    context "when this guild has a confirmation for the phash" do
      before do
        phash = create(:phash, phash: phash_hex)
        create(:phash_confirmation, phash:, server_configuration: config)
      end

      it "returns only the undo_verdict button" do
        custom_ids = buttons.map { |b| b[:custom_id] }
        expect(custom_ids).to eq(["mod:undo_verdict:#{phash_hex}"])
      end
    end

    context "when a different guild has a confirmation but this guild does not" do
      let!(:other_config) { create(:server_configuration) }

      before do
        phash = create(:phash, phash: phash_hex)
        create(:phash_confirmation, phash:, server_configuration: other_config)
      end

      it "returns confirm and dismiss buttons (foreign confirmation does not decide this guild)" do
        custom_ids = buttons.map { |b| b[:custom_id] }
        expect(custom_ids).to eq([
          "mod:confirm:#{phash_hex}",
          "mod:dismiss:#{phash_hex}"
        ])
      end
    end
  end

  describe ".decided?" do
    subject(:decided) { described_class.decided?(server_configuration: config, phash_hex:) }

    context "when no Phash row exists" do
      it { is_expected.to be(false) }
    end

    context "when a Phash exists with a confirmation for this guild" do
      before do
        phash = create(:phash, phash: phash_hex)
        create(:phash_confirmation, phash:, server_configuration: config)
      end

      it { is_expected.to be(true) }
    end

    context "when a Phash exists with a confirmation for a different guild only" do
      let!(:other_config) { create(:server_configuration) }

      before do
        phash = create(:phash, phash: phash_hex)
        create(:phash_confirmation, phash:, server_configuration: other_config)
      end

      it { is_expected.to be(false) }
    end
  end
end
