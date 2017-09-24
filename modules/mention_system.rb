module MentionSystem
    extend Discordrb::EventContainer
    extend Discordrb::Commands::CommandContainer

    attrs = {
        permission_level: 1,
        permission_message: false,
        usage: '.mention <user>',
        description: 'Mentions a user.'
    }
    command :mention, attrs do |event, *args|
        event.message.delete
        event.respond event.server.members.find { |member| member.name == args.join(' ') }.mention
    end

    message(contains: '@everyone') do |event|
        next if staff_user?(event.user)

        message = event.respond 'You are not allowed to use `@everyone`. Do you want to use `@here` instead?'
        message.react(EmojiTranslator.name_to_unicode('checkmark'))
        message.react(EmojiTranslator.name_to_unicode('crossmark'))
        event.bot.add_await(:"replace_#{message.id}", Discordrb::Events::ReactionAddEvent) do |reaction_event|
            next false unless (reaction_event.message.id == message.id) && (reaction_event.user.id == event.user.id)
            if reaction_event.emoji.name == EmojiTranslator.name_to_emoji('crossmark')
                event.channel.send_temporary_message 'Alright :)', 10
                message.delete
            elsif reaction_event.emoji.name == EmojiTranslator.name_to_emoji('checkmark')
                event.respond "#{event.message.user.name} said: #{event.message.content.gsub(/@everyone/, '@here')}"
                message.delete
            else
                next false
            end
        end
    end

    message(contains: '@here') do |event|
        next if staff_user?(event.user)
        next if event.message.content.include?('@everyone')

        message = event.respond 'Are you sure you want to tag `@here`?'
        message.react(EmojiTranslator.name_to_unicode('checkmark'))
        message.react(EmojiTranslator.name_to_unicode('crossmark'))
        event.bot.add_await(:"confirm_#{message.id}", Discordrb::Events::ReactionAddEvent) do |reaction_event|
            next false unless (reaction_event.message.id == message.id) && (reaction_event.user.id == event.user.id)
            if reaction_event.emoji.name == EmojiTranslator.name_to_emoji('crossmark')
                event.channel.send_temporary_message 'Alright :)', 10
                message.delete
            elsif reaction_event.emoji.name == EmojiTranslator.name_to_emoji('checkmark')
                event.respond "#{event.message.user.name} said: #{event.message.content.gsub(/@everyone/, '@here')}"
                message.delete
            else
                next false
            end
        end
    end

    private_class_method def self.staff_user?(user)
        !user.roles.find { |role| role.name == 'BotCommand' }.nil?
    end
end
