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
      :settings
    )
  end
end
