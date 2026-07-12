# frozen_string_literal: true

module Moderation
  module Interaction
    module CustomId
      PREFIX = "mod"

      module_function

      def confirm(phash_hex)
        "#{PREFIX}:confirm:#{phash_hex}"
      end

      def dismiss(phash_hex)
        "#{PREFIX}:dismiss:#{phash_hex}"
      end

      def undo_verdict(phash_hex)
        "#{PREFIX}:undo_verdict:#{phash_hex}"
      end

      def undo_punishment(user_id, punishment)
        "#{PREFIX}:undo_punishment:#{user_id}:#{punishment}"
      end

      def undo_punishment_args(custom_id)
        _prefix, _action, user_id, punishment = custom_id.split(":")
        {user_id: user_id.to_i, punishment:}
      end

      def parse(custom_id)
        _prefix, action, phash_hex = custom_id.split(":")
        {action: action&.to_sym, phash_hex:}
      end
    end
  end
end
