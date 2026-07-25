# frozen_string_literal: true

module Ops
  module BotSettings
    class Update < ApplicationOperation
      receives :owner_error_dms

      def call
        BotSetting.owner_error_dms = truthy?(owner_error_dms)
        ok(BotSetting.owner_error_dms?)
      end
    end
  end
end
