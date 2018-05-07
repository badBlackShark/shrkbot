# Allows users to mention @here, without letting them user @everyone. Won't interfere with staff users.
module Mentions
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'mention <user>',
    description: 'Mentions a user without letting them know it was you who mentioned them.'
  }
  command :mention, attrs do |event, *args|
    event.message.delete
    event.server.members.find { |member| member.name.casecmp?(args.join(' ')) }.mention
  end

  # Replaces @everyone with @here mentions in someone's message, if they want to.
  message(contains: '@everyone') do |event|
    # Staff should still be abled to just use @everyone
    next if SHRK.permission?(event.user, 1, event.server)

    message = event.respond 'You are not allowed to use `@everyone`. Do you want to use `@here` instead?'
    choice = Reactions.yes_no(message, event.user)
    if choice
      message.delete
      event.respond "#{event.message.user.mention} said: #{event.message.content.gsub(/@everyone/, '@here')}"
    elsif choice.nil?
      event.channel.send_temporary_message('Nevermind then.', 5)
      message.delete
    else
      event.channel.send_temporary_message('Alright :)', 5)
      message.delete
    end
  end

  # Since not being allowed to ping everyone also stops you from using @here, this allows users to do so again.
  # Works pretty much exactly like the @everyone replacement
  message(contains: '@here') do |event|
    next if SHRK.permission?(event.user, 1, event.server)
    # In case a message has @here and @everyone, just let one event handle it.
    next if event.message.content.include?('@everyone')

    message = event.respond 'Are you sure you want to tag `@here`?'

    choice = Reactions.yes_no(message, event.user)
    if choice
      message.delete
      event.respond "#{event.message.user.mention} said: #{event.message.content}"
    elsif choice.nil?
      event.channel.send_temporary_message('Nevermind then.', 5)
      message.delete
    else
      event.channel.send_temporary_message('Alright :)', 5)
      message.delete
    end
  end
end
