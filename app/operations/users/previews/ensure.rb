# frozen_string_literal: true

module Ops
  module Users
    module Previews
      class Ensure < ApplicationOperation
        def call
          user = ::User.find_or_create_by!(discord_id: PreviewData.user[:discord_id]) do |record|
            record.username = PreviewData.user[:username]
            record.display_name = PreviewData.user[:display_name]
          end
          ok(user)
        end
      end
    end
  end
end
