# frozen_string_literal: true

module Moderation
  module ImageScanning
    module Classifier
      THRESHOLDS = {
        "relaxed" => {flag: 5, remove: 8},
        "standard" => {flag: 3, remove: 6},
        "strict" => {flag: 2, remove: 4.5}
      }.freeze
      NEW_ACCOUNT_DAYS = 7
      KEYWORD_WEIGHT = 2
      OWN_CONFIRMED_RISK = 6
      FUZZY_RATIO = 0.2

      module_function

      def call(ocr_text:, hash_state:, signals:, settings:)
        canon = Canonicalizer.call(ocr_text)

        reasons = scam_rule_reasons(canon) + keyword_reasons(canon, settings)
        ocr_score = reasons.sum(&:weight)

        hash_reason = hash_reason(hash_state)
        reasons << hash_reason if hash_reason

        reasons.concat(amplifier_reasons(signals))
        risk = reasons.sum(&:weight)

        keyword_gate = reasons.any? { |reason| reason.key == :custom_keywords }
        content_signal = ocr_score > 0 || hash_state != :none
        thresholds = THRESHOLDS.fetch(settings.sensitivity)
        action = decide(risk, ocr_score, hash_state, content_signal, keyword_gate, thresholds)

        Verdict.new(action:, risk:, reasons:)
      end

      def decide(risk, ocr_score, hash_state, content_signal, keyword_gate, thresholds)
        return :allow unless content_signal

        action =
          if risk >= thresholds[:remove] && (ocr_score > 0 || hash_state == :own_confirmed)
            (hash_state == :foreign_confirmed) ? :flag_for_review : :remove
          elsif risk >= thresholds[:flag]
            :flag_for_review
          else
            :allow
          end

        (keyword_gate && action == :allow) ? :flag_for_review : action
      end

      def scam_rule_reasons(canon)
        matched = ScamRules::RULES.select { |rule| FuzzyMatcher.match?(matchable(rule), canon, ratio: FUZZY_RATIO) }
        matched.map { |rule| Reason.new(key: :rule, weight: rule[:weight], detail: rule[:pattern]) }
      end

      def matchable(rule)
        rule[:regex] ? Regexp.new(rule[:pattern]) : rule[:pattern]
      end

      def keyword_reasons(canon, settings)
        keywords = settings.custom_keywords
        return [] if keywords.empty?

        hits = keywords.count { |keyword| FuzzyMatcher.match?(Canonicalizer.call(keyword), canon, ratio: FUZZY_RATIO) }
        return [] if hits < settings.custom_keyword_min_hits

        [Reason.new(key: :custom_keywords, weight: KEYWORD_WEIGHT * hits, detail: hits)]
      end

      def amplifier_reasons(signals)
        reasons = []
        if signals[:account_age_days] < NEW_ACCOUNT_DAYS
          reasons << Reason.new(key: :new_account, weight: 2, detail: signals[:account_age_days].floor)
        end
        reasons << Reason.new(key: :has_link, weight: 1) if signals[:has_link]
        reasons << Reason.new(key: :no_role, weight: 0.5) unless signals[:has_role]
        reasons
      end

      def hash_reason(hash_state)
        return nil if hash_state == :none

        weight = (hash_state == :own_confirmed) ? OWN_CONFIRMED_RISK : 0
        Reason.new(key: hash_state, weight:)
      end

      private_class_method :decide, :scam_rule_reasons, :matchable, :keyword_reasons, :amplifier_reasons, :hash_reason
    end
  end
end
