# frozen_string_literal: true

module Integrations
  class Language
    MODEL_PATH = Rails.root.join("vendor/fasttext/lid.176.ftz")
    CODES = %w[af als am an ar arz as ast av az azb ba bar bcl be bg bh bn bo bpy br bs bxr ca cbk ce ceb ckb co cs cv cy da de diq dsb dty dv el eml en eo es et eu fa fi fr frr fy ga gd gl gn gom gu gv he hi hif hr hsb ht hu hy ia id ie ilo io is it ja jbo jv ka kk km kn ko krc ku kv kw ky la lb lez li lmo lo lrc lt lv mai mg mhr min mk ml mn mr mrj ms mt mwl my myv mzn nah nap nds ne new nl nn no oc or os pa pam pfl pl pms pnb ps pt qu rm ro ru rue sa sah sc scn sco sd sh si sk sl so sq sr su sv sw ta te tg th tk tl tr tt tyv ug uk ur uz vec vep vi vls vo wa war wuu xal xmf yi yo yue zh].freeze
    MIN_LENGTH = 50
    MIN_CONFIDENCE = 0.5
    ALERT_INTERVAL = 1.day

    def self.detect(text)
      new(text).detect
    rescue StandardError, LoadError => error
      Rails.logger.error("Integrations: language detection failed: #{error.full_message(highlight: false)}")
      alert_owner(error)
      nil
    end

    def self.alert_owner(error)
      return unless Rails.cache.write("integrations/language/alert/#{error.class}", true, unless_exist: true, expires_in: ALERT_INTERVAL)

      ReportPollBugsJob.perform_later(["Language detection: #{error.class}: #{error.message}"])
    end
    private_class_method :alert_owner

    def self.model
      require "fasttext"
      @model ||= FastText.load_model(MODEL_PATH.to_s)
    end

    def initialize(text)
      @prose = prose(text.to_s)
    end

    def detect
      return if @prose.length < MIN_LENGTH

      code, confidence = self.class.model.predict(@prose, k: 1).first
      code if confidence >= MIN_CONFIDENCE
    end

    private

    def prose(text)
      text
        .gsub(/!\[[^\]]*\]\([^)]*\)/, " ")
        .gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')
        .gsub(%r{https?://\S+}, " ")
        .gsub(/[*_#>`|~]+/, " ")
        .squish
    end
  end
end
