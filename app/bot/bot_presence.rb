module BotPresence
  LISTENING = 2

  module_function

  def activity_text(server_count)
    "/help • #{server_count} #{"server".pluralize(server_count)}"
  end

  def update(bot, server_count)
    bot.update_status("online", activity_text(server_count), nil, 0, false, LISTENING)
  end
end
