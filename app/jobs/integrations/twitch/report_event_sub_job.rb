# frozen_string_literal: true

module Integrations
  module Twitch
    class ReportEventSubJob < ApplicationJob
      include NotifiesOwner

      queue_as :default

      def perform(lines)
        notify_owner(["Twitch EventSub needs a look:", *owner_list(lines)].join("\n"))
      end
    end
  end
end
