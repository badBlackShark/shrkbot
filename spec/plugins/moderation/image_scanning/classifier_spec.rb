# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::Classifier do
  subject(:verdict) do
    described_class.call(
      ocr_text:,
      hash_state:,
      signals:,
      settings:,
      new_account_age_days:
    )
  end

  let(:ocr_text) { "" }
  let(:hash_state) { :none }
  let(:new_account_age_days) { 30 }
  let(:signals) { {account_age_days: 365, has_link: false, has_role: true} }
  let(:sensitivity) { "standard" }
  let(:custom_keywords) { [] }
  let(:custom_keyword_min_hits) { 1 }
  let(:settings) do
    instance_double(
      "Settings",
      sensitivity:,
      custom_keywords:,
      custom_keyword_min_hits:
    )
  end

  context "content-signal lock with only amplifier signals" do
    let(:ocr_text) { "hello friends nice weather" }
    let(:signals) { {account_age_days: 1, has_link: true, has_role: false} }

    it "allows despite amplifier-driven risk" do
      expect(verdict.action).to eq(:allow)
    end

    it "still accumulates amplifier risk" do
      expect(verdict.risk).to eq(3.5)
    end
  end

  context "clear scam text on standard sensitivity" do
    let(:ocr_text) { "promo code withdraw tuzawin" }

    it "removes" do
      expect(verdict.action).to eq(:remove)
    end
  end

  describe "sensitivity presets" do
    context "relaxed (flag 5, remove 8)" do
      let(:sensitivity) { "relaxed" }

      context "score 4" do
        let(:ocr_text) { "casino vyro" }

        it "allows below flag" do
          expect(verdict.action).to eq(:allow)
        end
      end

      context "score 5" do
        let(:ocr_text) { "casino tuzawin" }

        it "flags at threshold" do
          expect(verdict.action).to eq(:flag_for_review)
        end
      end

      context "score 8" do
        let(:ocr_text) { "casino tuzawin promo code" }

        it "removes at threshold" do
          expect(verdict.action).to eq(:remove)
        end
      end
    end

    context "standard (flag 3, remove 6)" do
      let(:sensitivity) { "standard" }

      context "score 2" do
        let(:ocr_text) { "casino" }

        it "allows below flag" do
          expect(verdict.action).to eq(:allow)
        end
      end

      context "score 4" do
        let(:ocr_text) { "casino vyro" }

        it "flags between thresholds" do
          expect(verdict.action).to eq(:flag_for_review)
        end
      end

      context "score 6" do
        let(:ocr_text) { "tuzawin promo code" }

        it "removes at threshold" do
          expect(verdict.action).to eq(:remove)
        end
      end
    end

    context "strict (flag 2, remove 4.5)" do
      let(:sensitivity) { "strict" }

      context "score 2" do
        let(:ocr_text) { "casino" }

        it "flags at threshold" do
          expect(verdict.action).to eq(:flag_for_review)
        end
      end

      context "score 4" do
        let(:ocr_text) { "casino vyro" }

        it "flags below remove" do
          expect(verdict.action).to eq(:flag_for_review)
        end
      end

      context "score 5" do
        let(:ocr_text) { "casino tuzawin" }

        it "removes above threshold" do
          expect(verdict.action).to eq(:remove)
        end
      end
    end
  end

  describe "amplifiers" do
    let(:ocr_text) { "casino" }

    context "new account" do
      let(:signals) { {account_age_days: 1, has_link: false, has_role: true} }

      it "adds 2 to risk" do
        expect(verdict.risk).to eq(4)
      end

      it "records the reason" do
        expect(verdict.reasons.map(&:key)).to include(:new_account)
      end
    end

    context "has link" do
      let(:signals) { {account_age_days: 365, has_link: true, has_role: true} }

      it "adds 1 to risk" do
        expect(verdict.risk).to eq(3)
      end

      it "records the reason" do
        expect(verdict.reasons.map(&:key)).to include(:has_link)
      end
    end

    context "no role" do
      let(:signals) { {account_age_days: 365, has_link: false, has_role: false} }

      it "adds 0.5 to risk" do
        expect(verdict.risk).to eq(2.5)
      end

      it "records the reason" do
        expect(verdict.reasons.map(&:key)).to include(:no_role)
      end
    end

    context "aged account with role and no link" do
      it "adds no amplifier risk" do
        expect(verdict.risk).to eq(2)
      end
    end

    context "with a raised new-account cutoff" do
      let(:new_account_age_days) { 60 }
      let(:ocr_text) { "promo code withdraw tuzawin" }
      let(:signals) { {account_age_days: 45, has_link: false, has_role: true} }

      it "treats an account within the cutoff as new" do
        expect(verdict.reasons.map(&:key)).to include(:new_account)
      end
    end
  end

  describe "custom keywords" do
    let(:ocr_text) { "join our discord group chat" }
    let(:custom_keywords) { ["discord"] }

    context "hits meet the minimum" do
      let(:custom_keyword_min_hits) { 1 }

      it "adds 2 per hit" do
        expect(verdict.risk).to eq(2)
      end

      it "records the reason" do
        expect(verdict.reasons.map(&:key)).to include(:custom_keywords)
      end

      it "floors the verdict at flag even when the score is below the flag threshold" do
        expect(verdict.action).to eq(:flag_for_review)
      end
    end

    context "hits below the minimum" do
      let(:custom_keyword_min_hits) { 2 }

      it "contributes nothing" do
        expect(verdict.risk).to eq(0)
      end

      it "produces no content signal" do
        expect(verdict.action).to eq(:allow)
      end
    end

    context "phrase keyword" do
      let(:ocr_text) { "join our private group today" }
      let(:custom_keywords) { ["private group"] }

      it "matches multi-word keywords" do
        expect(verdict.reasons.map(&:key)).to include(:custom_keywords)
      end
    end

    context "fuzzy keyword variant" do
      let(:ocr_text) { "join telegran now" }
      let(:custom_keywords) { ["telegram"] }

      it "matches a typo variant" do
        expect(verdict.reasons.map(&:key)).to include(:custom_keywords)
      end
    end

    context "empty keyword list" do
      let(:custom_keywords) { [] }

      it "contributes no keyword risk" do
        expect(verdict.risk).to eq(0)
      end
    end

    context "multiple hits" do
      let(:ocr_text) { "discord telegram group" }
      let(:custom_keywords) { ["discord", "telegram"] }
      let(:custom_keyword_min_hits) { 2 }

      it "adds 2 per hit" do
        expect(verdict.risk).to eq(4)
      end
    end
  end

  describe "hash state" do
    context "foreign-hash cap" do
      let(:hash_state) { :foreign_confirmed }
      let(:ocr_text) { "promo code withdraw tuzawin" }

      it "caps at flag despite reaching remove risk" do
        expect(verdict.action).to eq(:flag_for_review)
      end

      it "never removes" do
        expect(verdict.action).not_to eq(:remove)
      end
    end

    context "own_confirmed" do
      let(:hash_state) { :own_confirmed }

      it "adds 8 to risk" do
        expect(verdict.risk).to eq(8)
      end

      context "standard sensitivity with empty ocr text" do
        let(:sensitivity) { "standard" }

        it "removes on the hash content signal" do
          expect(verdict.action).to eq(:remove)
        end
      end

      context "strict sensitivity with empty ocr text" do
        let(:sensitivity) { "strict" }

        it "removes on the hash content signal" do
          expect(verdict.action).to eq(:remove)
        end
      end

      context "relaxed sensitivity alone" do
        let(:sensitivity) { "relaxed" }

        it "removes at the remove threshold (risk 8 == remove 8)" do
          expect(verdict.action).to eq(:remove)
        end
      end
    end

    context "global_confirmed" do
      let(:hash_state) { :global_confirmed }

      it "adds 6 to risk" do
        expect(verdict.risk).to eq(6)
      end

      context "relaxed sensitivity alone" do
        let(:sensitivity) { "relaxed" }

        it "flags below the remove threshold (risk 6 < remove 8)" do
          expect(verdict.action).to eq(:flag_for_review)
        end
      end

      context "standard sensitivity with empty ocr text" do
        let(:sensitivity) { "standard" }

        it "removes on the hash content signal" do
          expect(verdict.action).to eq(:remove)
        end
      end

      context "strict sensitivity with empty ocr text" do
        let(:sensitivity) { "strict" }

        it "removes on the hash content signal" do
          expect(verdict.action).to eq(:remove)
        end
      end
    end

    context "foreign_confirmed with amplifier-only risk" do
      let(:hash_state) { :foreign_confirmed }
      let(:sensitivity) { "strict" }
      let(:signals) { {account_age_days: 1, has_link: true, has_role: false} }

      it "does not remove without ocr score or own hash" do
        expect(verdict.action).not_to eq(:remove)
      end

      it "flags instead" do
        expect(verdict.action).to eq(:flag_for_review)
      end
    end
  end

  describe "rule reasons" do
    let(:ocr_text) { "casino" }

    it "carries the matched pattern in reason detail" do
      rule_reason = verdict.reasons.find { |r| r.key == :rule }
      expect(rule_reason).not_to be_nil
      expect(rule_reason.detail).to be_a(String)
      expect(rule_reason.detail).not_to be_empty
    end

    it "carries the rule weight in reason weight" do
      rule_reason = verdict.reasons.find { |r| r.key == :rule }
      expect(rule_reason.weight).to be > 0
    end

    it "risk equals sum of reason weights" do
      expect(verdict.risk).to eq(verdict.reasons.sum(&:weight))
    end
  end
end
