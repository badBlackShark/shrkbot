# Allows users to mention @here, without letting them user @everyone. Won't interfere with staff users.
module Mentions
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  # TODO: Multithread

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: '.mention <user>',
    description: 'Mentions a user without letting them know it was you who mentioned them.'
  }
  command :mention, attrs do |event, *args|
    event.message.delete
    event.respond event.server.members.find { |member| member.name.casecmp?(args.join(' ')) }.mention
  end

  # Replaces @everyone with @here mentions in someone's message, if they want to.
  message(contains: '@everyone') do |event|
    next if staff_user?(event.user) # Staff should still be abled to just use @everyone

    message = event.respond 'You are not allowed to use `@everyone`. Do you want to use `@here` instead?'
    message.react(Emojis.name_to_unicode('checkmark'))
    message.react(Emojis.name_to_unicode('crossmark'))

    SSB.add_await(:"replace_#{message.id}", Discordrb::Events::ReactionAddEvent) do |reaction_event|
      # Only the user who sent the message should be abled to confirm / deny.
      next false unless (reaction_event.message.id == message.id) && (reaction_event.user.id == event.user.id)
      if reaction_event.emoji.name == Emojis.name_to_emoji('crossmark')
        event.channel.send_temporary_message 'Alright :)', 10
        message.delete
      elsif reaction_event.emoji.name == Emojis.name_to_emoji('checkmark')
        event.respond "#{event.message.user.mention} said: #{event.message.content.gsub(/@everyone/, '@here')}"
        message.delete
      else
        false # Ignore reactions that aren't the two we want
      end
    end
  end

  # Since not being allowed to ping everyone also stops you from using @here, this allows users to do so again.
  # Works pretty much exactly like the @everyone replacement
  message(contains: '@here') do |event|
    next if staff_user?(event.user)
    # In case a message has @here and @everyone, just let one event handle it.
    next if event.message.content.include?('@everyone')

    message = event.respond 'Are you sure you want to tag `@here`?'
    message.react(Emojis.name_to_unicode('checkmark'))
    message.react(Emojis.name_to_unicode('crossmark'))

    SSB.add_await(:"confirm_#{message.id}", Discordrb::Events::ReactionAddEvent) do |reaction_event|
      next false unless (reaction_event.message.id == message.id) && (reaction_event.user.id == event.user.id)

      if reaction_event.emoji.name == Emojis.name_to_emoji('crossmark')
        event.channel.send_temporary_message 'Alright :)', 10
        message.delete
      elsif reaction_event.emoji.name == Emojis.name_to_emoji('checkmark')
        event.respond "#{event.message.user.mention} said: #{event.message.content}"
        message.delete
      else
        false
      end
    end
  end

  private_class_method def self.staff_user?(user)
    !user.roles.find { |role| role.name == 'BotCommand' }.nil?
  end
end
