# frozen_string_literal: true

module Moderation
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
      reasons = []

      ocr_score = scam_rule_score(canon, reasons) + keyword_score(canon, settings, reasons)

      risk = ocr_score
      risk += OWN_CONFIRMED_RISK if hash_state == :own_confirmed
      risk += amplifier_score(signals, reasons)

      reasons << hash_state unless hash_state == :none

      content_signal = ocr_score > 0 || hash_state != :none
      keyword_gate = reasons.include?(:custom_keywords)
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

    def amplifier_score(signals, reasons)
      score = 0
      if signals[:account_age_days] < NEW_ACCOUNT_DAYS
        score += 2
        reasons << :new_account
      end
      if signals[:has_link]
        score += 1
        reasons << :has_link
      end
      unless signals[:has_role]
        score += 0.5
        reasons << :no_role
      end
      score
    end

    def scam_rule_score(canon, reasons)
      matched = ScamRules::RULES.select { |rule| FuzzyMatcher.match?(matchable(rule), canon, ratio: FUZZY_RATIO) }
      reasons.concat(matched.map { |rule| rule[:pattern] })
      matched.sum { |rule| rule[:weight] }
    end

    def matchable(rule)
      rule[:regex] ? Regexp.new(rule[:pattern]) : rule[:pattern]
    end

    def keyword_score(canon, settings, reasons)
      keywords = settings.custom_keywords
      return 0 if keywords.empty?

      hits = keywords.count { |keyword| FuzzyMatcher.match?(Canonicalizer.call(keyword), canon, ratio: FUZZY_RATIO) }
      return 0 if hits < settings.custom_keyword_min_hits

      reasons << :custom_keywords
      KEYWORD_WEIGHT * hits
    end

    private_class_method :decide, :amplifier_score, :scam_rule_score, :matchable, :keyword_score
  end
end
