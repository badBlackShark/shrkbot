# Allows you to set prefixes on a by-server basis.
module Prefixes
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  message(with_text: '.prefix') do |event|
    event.respond "This server's prefix is `#{$prefixes[event.server.id] || '.'}`"
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'setPrefix <newPrefix>',
    description: 'Sets the prefix for this server. '\
                 'Don\'t set this to a custom emoji, unless you want to brick your bot :)',
    min_args: 1
  }
  command :setprefix, attrs do |event, new_prefix|
    DB.update_string_value("shrk_server_#{event.server.id}".to_sym, :prefix, new_prefix)
    $prefixes[event.server.id] = new_prefix

    event.message.react(Emojis.name_to_unicode('checkmark'))
    LOGGER.log(event.server, "The prefix has been changed to `#{new_prefix}`")
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    description: 'Resets the prefix for this server.',
    usage: 'resetPrefix'
  }
  command :resetprefix, attrs do |event|
    DB.update_string_value("shrk_server_#{event.server.id}".to_sym, :prefix, nil)
    $prefixes[event.server.id] = nil

    event.message.react(Emojis.name_to_unicode('checkmark'))
    LOGGER.log(event.server, 'The prefix has been reset to `.`')
  end
end
