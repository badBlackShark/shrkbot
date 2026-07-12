# frozen_string_literal: true

module Moderation
  module ImageScanning
    ScanContext = Data.define(
      :bot,
      :server,
      :member,
      :channel_id,
      :message_id,
      :attachment_url,
      :signals,
      :new_account_age_days,
      :settings
    )
  end
end
