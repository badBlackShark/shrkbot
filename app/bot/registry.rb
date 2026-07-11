# frozen_string_literal: true

module Bot
  module Registry
    module_function

    def register(bots)
      @bots = Array(bots)
    end

    def all
      @bots || []
    end
  end
end
