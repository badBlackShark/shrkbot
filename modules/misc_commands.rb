# All the hardcoded BS goes in here :)
module MiscCommands
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

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
    description: 'Executes the given Ruby codeblock. You can use syntax highlighting.'
  }
  command :eval, attrs do |event|
    code = event.message.content.gsub(/```(rb)?/, '').gsub("#{$prefixes[event.server&.id] || '.'}eval ", '')
    begin
      output = eval(code)
      embed = Discordrb::Webhooks::Embed.new
      embed.add_field(
        name: 'Input',
        value: code.prepend("```rb\n") << '```'
      )
      output = nil if output.to_s.empty?
      embed.add_field(
        name: 'Output',
        value: "-> #{output || '-'}"
      )
      embed.color = 65280
      embed.title = 'Evaluation of code.'
      event.channel.send_embed('', embed)
    rescue Exception => e
      backtrace = e.backtrace.join("\n")
      'An error occured while evaluating your code: '\
      "```#{e}``` at ```#{backtrace.length > 1800 ? backtrace[0, backtrace.rindex(/\n/,1800)].rstrip << "\n..." : backtrace}```"
    end
  end
end
