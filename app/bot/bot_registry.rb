# frozen_string_literal: true

module BotRegistry
  module_function

  def register(bots)
    @bots = Array(bots)
  end

  def all
    @bots || []
  end
end
