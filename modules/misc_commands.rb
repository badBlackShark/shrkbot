# All the hardcoded BS goes in here :)
module MiscCommands
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  message(with_text: 'ping', permission_level: 2, permission_message: false) do |event|
    # next unless event.user.id == 94558130305765376
    message = event.respond 'fuck off'
    sleep 10
    message.edit "I mean, 'pong'"
    message.react(Emojis.name_to_unicode('heart'))
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'setGame <game>',
    description: 'Sets what the bots is playing.'
  }
  command :setgame, attrs do |event, *args|
    game = args.join(' ')
    SHRK.game = game
    event.message.delete
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'REEEEE',
    description: 'REEEEE!'
  }
  command :reeeee, attrs do |event|
    event.channel.send_embed('') do |embed|
      embed.image = Discordrb::Webhooks::EmbedImage.new(url: 'https://cdn.discordapp.com/attachments/345748230816006156/347070498078851103/Eternally_screaming.gif')
    end
    event.message.delete
  end

  attrs = {
    permission_level: 2,
    permission_message: false,
    usage: 'eval <code>',
    description: 'Executes the given codeblock. Syntax highlighting supported.'
  }
  command :eval, attrs do |event, *args|
    code = args.join(' ').gsub(/```(rb)?/, '')
    begin
      output = eval(code)
      embed = Discordrb::Webhooks::Embed.new
      embed.add_field(
        name: 'Input',
        value: code.prepend("```rb\n") << '```'
      )
      embed.add_field(
        name: 'Output',
        value: output || '-'
      )
      embed.color = 1
      embed.title = 'Evaluation of code.'
      event.channel.send_embed('', embed)
    rescue Exception => e
      "An error occured while evaluation your code: "\
      "```#{e}``` at ```#{e.backtrace.join("\n")[0..1800].gsub(/\s\w+\s*$/, '...')}```"
    end
  end
end
