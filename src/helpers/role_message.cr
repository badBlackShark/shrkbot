class Shrkbot::RoleMessage
  def self.to_embed(roles : Array(Discord::Role))
    embed = Discord::Embed.new

    embed.title = "Assign yourself a role by reaction with the corresponding emoji. Unreact to unassign."

    if roles.empty?
      embed.description = "There are no self-assignable roles at the moment."
    else
      emoji = "a"
      embed.description = String.build do |str|
        roles.each do |role|
          str << "• #{role.name} [#{Utilities::Emojis.name_to_emoji(emoji)}]\n\n"
          emoji = emoji.succ # :^)
        end
      end
    end
    embed.colour = 0x38AFE5
    embed.footer = Discord::EmbedFooter.new(text: "Moderators can react with \"🔄\" to refresh this message.")

    return embed
  end
end
