# frozen_string_literal: true

module Integrations
  class ReportPollBugsJob < ApplicationJob
    include NotifiesOwner

    queue_as :default

    def perform(lines)
      notify_owner(["Polling hit a bug in shrkbot:", *owner_list(lines)].join("\n"))
    end
  end
end
