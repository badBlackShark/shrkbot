# frozen_string_literal: true

module Integrations
  module Twitch
    Channel = Data.define(:broadcaster_id, :title, :category_id, :category_name)
  end
end
