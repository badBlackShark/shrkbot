# frozen_string_literal: true

module Integrations
  module Twitch
    User = Data.define(:id, :login, :display_name, :profile_image_url)
  end
end
