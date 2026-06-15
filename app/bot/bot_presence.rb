# Bot presence: "Listening to /help • N servers". Pure text builder + a method
# that pushes it via the duck-typed bot (#update_status, #servers).
module BotPresence
  LISTENING = 2 # discordrb activity_type for "Listening to"

  module_function

  def activity_text(server_count)
    "/help • #{server_count} #{"server".pluralize(server_count)}"
  end

  def update(bot)
    bot.update_status("online", activity_text(bot.servers.size), nil, 0, false, LISTENING)
  end
end
