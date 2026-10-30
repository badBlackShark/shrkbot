# frozen_string_literal: true

module Integrations
  module Twitch
    Segment = Data.define(
      :id,
      :start_time,
      :end_time,
      :title,
      :category_id,
      :category_name,
      :canceled_until,
      :recurring
    )
  end
end
