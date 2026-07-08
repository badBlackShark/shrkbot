# frozen_string_literal: true

module Moderation
  module CustomId
    PREFIX = "mod"

    module_function

    def confirm(phash_hex)
      "#{PREFIX}:confirm:#{phash_hex}"
    end

    def dismiss(phash_hex)
      "#{PREFIX}:dismiss:#{phash_hex}"
    end

    def dismiss_confirm(phash_hex)
      "#{PREFIX}:dismiss_confirm:#{phash_hex}"
    end

    def parse(custom_id)
      _prefix, action, phash_hex = custom_id.split(":")
      {action: action&.to_sym, phash_hex:}
    end
  end
end
