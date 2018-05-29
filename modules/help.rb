# I'll help you :]
module Help
  extend Discordrb::Commands::CommandContainer
  extend self

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

  private

  def send_single_command_embed(event, cmd)
    command = SHRK.commands.find { |name, _| name.casecmp(cmd.to_sym).zero? }&.fetch(1)
    return "The command `#{cmd}` doesn't exist." unless command
    event.channel.send_embed do |embed|
      embed.colour = 3715045
      embed.add_field(
        name: 'Description',
        value: command.attributes[:description] || '*No description given.*'
      )
      embed.add_field(
        name: 'Usage',
        value: "`#{command.attributes[:usage]&.dup&.prepend($prefixes[event.server.id] || '.') || 'No usage described.'}`"
      )
      embed.footer = {
        text: "Command \"#{command.attributes[:usage]&.split&.first || command.name}\"",
        icon_url: SHRK.profile.avatar_url
      }
      embed.timestamp = Time.now
    end
  end

  def send_all_commands_embed(event)
    cmds = SHRK.commands.select { |_, cmd| cmd.attributes[:permission_level].zero? }
    staff_cmds = SHRK.commands.select { |_, cmd| cmd.attributes[:permission_level] == 1 }

    is_staff = SHRK.permission?(event.user, 1, event.server)

    embed = Discordrb::Webhooks::Embed.new
    field_value = ''

    # Commands that don't have a usage described are considered hidden, and won't be displayed.
    cmds.values.map { |c| c.attributes[:usage]&.split&.first }.compact.sort.each do |name|
      field_value << "• #{name}\n"
    end
    embed.add_field(
      name: 'Regular commands:',
      value: field_value
    )

    if is_staff
      field_value = ''

      # Commands that don't have a usage described are considered hidden, and won't be displayed.
      staff_cmds.values.map { |c| c.attributes[:usage]&.split&.first }.compact.sort.each do |name|
        field_value << "• #{name}\n"
      end
      embed.add_field(
        name: 'Staff commands:',
        value: field_value
      )
    end

    if event.user.id == 94558130305765376
      field_value = ''
      tbs_cmds = SHRK.commands.select { |_, cmd| cmd.attributes[:permission_level] == 2 }

      tbs_cmds.values.map(&:name).sort.each do |cmd|
        field_value << "• #{cmd}\n"
      end

      embed.add_field(
        name: "Shark's commands:",
        value: field_value
      )
    end

    embed.title = 'All commands you can use.'
    embed.colour = 3715045
    embed.footer = {
      text: 'Commands are case-insensitive.',
      icon_url: SHRK.profile.avatar_url
    }
    embed.timestamp = Time.now

    command_count = cmds.keys.count
    command_count += staff_cmds.keys.count if is_staff

    if command_count >= 50
      event.user.pm.send_embed('', embed)
      'I sent you a DM with a list of my commands.'
    else
      event.channel.send_embed('', embed)
      nil
    end
  end
end
