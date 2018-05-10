# The messaged people can use to assign roles to themselves.
class RoleMessage
  # One assignment per hour.
  @assignment_bucket = Discordrb::Commands::Bucket.new(nil, nil, 3600)
  # Returns the message object of the role message, whether it existed or not.
  def self.send(server)
    role_message_is_valid?(server) ? (return role_message(server.id)) : delete_role_message(server)

    message = send_role_embed(server, get_assignment_channel(server.id))
    # So you can already click the reactions while the bot is creating them
    Thread.new { add_reactions(server, message) }
    add_role_await(server, message)

    DB.update_value("shrk_server_#{server.id}".to_sym, :role_message_id, message.id)

    message
  end

  # Deletes the old role message and sends a new one.
  def self.send!(server)
    delete_role_message(server)
    send(server)
  end

  def self.delete_role_message(server)
    channel = get_assignment_channel(server.id)
    channel.message(DB.read_value("shrk_server_#{server.id}".to_sym, :role_message_id))&.delete
  end

  def self.role_message(server_id)
    channel = get_assignment_channel(server_id)
    channel.message(DB.read_value("shrk_server_#{server_id}".to_sym, :role_message_id))
  end

  def self.add_reactions(server, message)
    server_roles = DB.read_column("shrk_server_#{server.id}".to_sym, :roles)
    emoji = 'a'
    reactions = []
    server_roles.length.times do
      reactions << Emojis.name_to_emoji(emoji).to_s
      emoji.succ! # :^)
    end
    Reactions.spam_reactions(message, reactions)
  end

  def self.refresh_reactions(server)
    message = channel.message(DB.read_value("shrk_server_#{server.id}".to_sym, :role_message_id))
    message ||= send(server)
    message.delete_all_reactions

    add_reactions(server, message)
  end

  def self.add_role_await(server, message)
    SHRK.add_await(:"roles_#{message.id}", Discordrb::Events::ReactionAddEvent) do |event|
      next false unless event.message.id == message.id
      # Reaction events are broken, needs the check to make sure it's actually the event I want.
      next false if event.user.id == BOT_ID

      role_id = emoji_to_role_id(server, event.emoji.name)
      next false unless role_id
      next false if event.user.role?(role_id)

      if (sec_left = @assignment_bucket.rate_limited?(event.user))
        time_left = "#{sec_left.to_i / 60} minutes and #{sec_left.to_i % 60} seconds"
        event.user.pm("You can't assign yourself another role for #{time_left}.")
        LOGGER.log(event.server, "#{event.user.distinct} tried to give himself the role "\
          "**#{id_to_role(event.server, role_id)}**, but still has **#{time_left}** cooldown.")
        next false
      end
      add_role_to_user(event.user, server, role_id)
      false
    end
  end

  def self.init_assignment_channel(server)
    return if DB.read_value("shrk_server_#{server.id}".to_sym, :assignment_channel)
    # Assignment channel defaults to the rules channel...
    assignment_channel = server.channels.find { |channel| channel.name.include?('rules') } ||
                         server.default_channel
    # ...or the top channel, if there is no rules channel.

    DB.unique_insert("shrk_server_#{server.id}".to_sym, :assignment_channel, assignment_channel.id)
    LOGGER.log(
      server,
      "Set <##{assignment_channel.id}> as the channel where the role-assignment " \
      'messages will be sent. You can change it by using the `setAssignmentChannel` command.'
    )
  end

  # Checks if the role message exists and has the correct amount of reactions.
  private_class_method def self.role_message_is_valid?(server)
    (message = role_message(server.id)) &&
    message.reactions.keys.count == DB.read_column("shrk_server_#{server.id}".to_sym, :roles).count
  end

  private_class_method def self.add_role_to_user(user, server, role_id)
    user_roles = user.roles.map(&:id)
    assignable_roles = DB.read_column("shrk_server_#{server.id}".to_sym, :roles)

    delete_existing_roles(user, server, assignable_roles, user_roles)
    user.add_role(role_id)

    user.pm("You now have the role \"#{id_to_role(server, role_id)}\" on \"#{server.name}\"")
    LOGGER.log(server, "#{user.distinct} gave himself the role \"#{id_to_role(server, role_id)}\".")
  end

  private_class_method def self.delete_existing_roles(user, server, assignable_roles, user_roles)
    assignable_roles.each do |role|
      if user_roles.include?(role)
        user.remove_role(server.roles.find { |s_role| s_role.id == role })
        sleep 0.1 # Required so everything works as intended.
      end
    end
  end

  private_class_method def self.get_assignment_channel(server_id)
    SHRK.channel(DB.read_value("shrk_server_#{server_id}".to_sym, :assignment_channel))
  end

  private_class_method def self.send_role_embed(server, channel)
    server_roles = DB.read_column("shrk_server_#{server.id}".to_sym, :roles)

    emoji = 'a'
    field_value = ''
    server_roles.sort_by { |r| id_to_role(server, r) }.each do |role_id|
      role = id_to_role(server, role_id)
      # Removes roles that don't exist anymore
      next DB.delete_value("shrk_server_#{server.id}".to_sym, :roles, role_id) unless role
      field_value << "• #{role}\t[#{Emojis.name_to_emoji(emoji)}]\n\n"
      emoji.succ! # :^)
    end
    field_value = 'There are no self assignable roles.' if field_value == ''

    channel.send_embed do |embed|
      embed.add_field(
        name: 'All roles you can assign to yourself.',
        value: field_value
      )
      embed.footer = {
        text: 'Click a reaction to assign a role to yourself.',
        icon_url: SHRK.profile.avatar_url
      }
    end
  end

  private_class_method def self.emoji_to_role_id(server, emoji)
    # Currently only 26 roles per server are supported
    current_emoji = 'a'
    roles = DB.read_column("shrk_server_#{server.id}".to_sym, :roles).sort_by { |r| id_to_role(server, r) }
    26.times do |i|
      return roles[i] if emoji == Emojis.name_to_emoji(current_emoji)
      current_emoji.succ! # :^)
    end
    nil
  end

  # Translates a role ID to the name of that role on a given server.
  private_class_method def self.id_to_role(server, role_id)
    server.roles.find { |role| role.id == role_id }&.name
  end
end
