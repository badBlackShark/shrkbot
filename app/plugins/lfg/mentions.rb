# frozen_string_literal: true

module Lfg
  module Mentions
    module_function

    def list(ids)
      ids.map { |id| "<@#{id}>" }.join(" ")
    end
  end
end
