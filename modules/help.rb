# I'll help you :]
module Help
  extend Discordrb::Commands::CommandContainer

  attrs = {
    description: 'Lists all the commands available to you, or shows help for one specific command.',
    usage: 'help <commandName>'
  }
  command :help, attrs do |event, command|
    if command
      send_single_command_embed(event, command)
    else
      send_all_commands_embed(event)
    end
  end

  private_class_method def self.send_single_command_embed(event, cmd)
    command = SHRK.commands.select { |name, _| name.casecmp(cmd.to_sym).zero? }
    return 'That command doesn\'t exist.' unless command.values.first
    event.channel.send_embed do |embed|
      embed.colour = 3715045
      embed.add_field(
        name: 'Description',
        value: command.values.first.attributes[:description] || '*No description given.*'
      )
      embed.add_field(
        name: 'Usage',
        value: "`#{$prefixes[event.server.id] || '.'}#{command.values.first.attributes[:usage]}`" ||
               '*No usage described.*'
      )
      embed.footer = {
        text: "Command \"#{command.keys.first}\"",
        icon_url: SHRK.profile.avatar_url
      }
      embed.timestamp = Time.now
    end
  end

  private_class_method def self.send_all_commands_embed(event)
    commands = SHRK.commands.select { |_, cmd| cmd.attributes[:permission_level].zero? }
    staff_commands = SHRK.commands.select { |_, cmd| cmd.attributes[:permission_level] == 1 }

    is_staff = SHRK.permission?(event.user, 1, event.server)

    embed = Discordrb::Webhooks::Embed.new
    field_value = ''

    commands.keys.sort.each do |name|
      field_value << "• #{name}\n"
    end
    embed.add_field(
      name: 'Regular commands:',
      value: field_value
    )

    if is_staff
      field_value = ''
      staff_commands.keys.sort.each do |name|
        field_value << "• #{name}\n"
      end
      embed.add_field(
        name: 'Staff commands:',
        value: field_value
      )
    end

    embed.colour = 3715045
    embed.footer = {
      text: 'All commands you can use.',
      icon_url: SHRK.profile.avatar_url
    }
    embed.timestamp = Time.now

    command_count = commands.keys.count
    command_count += staff_commands.keys.count if is_staff

    if command_count >= 50
      event.user.pm.send_embed('', embed)
      'I sent you a DM with a list of my commands.'
    else
      event.channel.send_embed('', embed)
      nil
    end
  end
end
