# frozen_string_literal: true

class ReportExhaustedJob < ApplicationJob
  include NotifiesOwner

  queue_as :default

  def perform(line)
    notify_owner(["A job gave up after #{ReportsExhaustion::ATTEMPTS} attempts:", *owner_list([line])].join("\n"))
  end
end
