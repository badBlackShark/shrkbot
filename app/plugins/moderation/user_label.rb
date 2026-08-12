# frozen_string_literal: true

module Moderation
  module UserLabel
    module_function

    def for(user)
      "#{user.mention} (#{user.username})"
    end
  end
end
