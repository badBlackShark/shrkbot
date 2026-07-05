# frozen_string_literal: true

module BotPresence
  LISTENING = 2

  module_function

  def activity_text(server_count)
    "/info • #{server_count} #{"server".pluralize(server_count)}"
  end

  def update(bot, server_count)
    bot.update_status("online", activity_text(server_count), nil, 0, false, LISTENING)
  end
end
