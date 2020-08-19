class Shrkbot::PluginList
  include YAML::Serializable

  @first = true

  # plugin_name => (command_name => command)
  def initialize(@plugins : Hash(String, Hash(String, HelpCommand)))
  end

  def to_embed_fields(level : PermissionLevel, guild : Discord::Snowflake?)
    return @plugins.map do |name, commands|
      cmds = case level
             when PermissionLevel::User
               commands.values.select { |cmd| cmd.perm_level == 0 }
             when PermissionLevel::Moderator
               commands.values.select { |cmd| cmd.perm_level <= 1 }
             else
               commands.values
             end
      cmds.select! { |cmd| PluginSelector.enabled?(guild, name.downcase) }
      if cmds.empty?
        nil
      else
        Discord::EmbedField.new(name: name, value: cmds.map(&.to_s(guild)).join("\n"))
      end
    end.compact
  end

  def single_command(cmd : String, level : PermissionLevel, guild : Discord::Snowflake?)
    # I have actually not found a better location to initialize a matcher, since I don't want it to
    # be serialized, initialize is never called and @plugins can't be used before initialization.
    if @first
      @@matcher = Utilities::FuzzyMatch.new(@plugins.map { |_n, cmds| cmds.keys }.flatten)
      @first = false
    end

    cmd = @@matcher.not_nil!.find(cmd)
    return :not_found if cmd.empty?

    # We can .not_nil! here because the matcher guarantees us a match
    command = @plugins.map { |_n, cmds| cmds.find { |_n, c| c.name.downcase == cmd } }.compact.first.not_nil![1]
    return :no_perms if command.perm_level > level.value

    command.long_form(guild)
  end
end
