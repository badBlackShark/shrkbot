# Create TODO lists
module Todo
  extend Discordrb::Commands::CommandContainer
  extend self

  # Todo entries will get unique IDs per user. This is a User_ID => next_entry_ID map.
  @next_id = 0

  def init
    DB.create_table(
      'shrk_todo',
      id: :bigint,
      user: :bigint,
      entry: :text,
      server: :bigint
    )

    entries = DB.read_all(:shrk_todo)
    # This is the highest ID currently in the database, so we need to add 1 for the upcoming ID.
    @id = (entries.max_by { |e| e[:id] }&.fetch(:id) || - 1) + 1
  end

  attrs = {
    usage: 'todo <entry OR id> <flags>',
    description: 'Creates an entry, if <entry> is given. Otherwise, displays the TODO list. '\
                 "Flags:\n`--server`: Hides the entry from all servers but the one it was created on.\n"\
                 "`--delete`: Deletes the entry with the given <id>.\n"\
                 "`--all`: Also displays entries hidden with `--server`.\n"\
                 '`--clear`: Clears your TODO list.'
  }
  command :todo, attrs do |event, *args|
    entry = args.reject { |a| a =~ /--server|--all|--delete|--clear/ }.join(' ')
    if args.any? { |a| a.casecmp?('--clear') }
      DB.select_rows(:shrk_todo, :user, event.user.id).length.downto(0) do |i|
        delete_entry(event, i)
      end
      'Successfully cleared your TODO list.'
    elsif entry.empty?
      show_todo_list(event, args.any? { |a| a.casecmp?('--all') })
    elsif args.any? { |a| a.casecmp?('--delete') } && !(id = args.select { |a| a =~ /\d+/ }.join).empty?
      delete_entry(event, id.gsub(/#/, '').to_i - 1)
    else
      server_only = args.any? { |a| a.casecmp?('--server') }
      # Not taking entry here to preserve newlines.
      create_entry(event, event.message.content.sub("#{$prefixes[event.server.id] || '.'}todo ", ''), server_only)
    end
  end

  private

  def create_entry(event, entry, server_only)
    DB.insert_row(
      :shrk_todo,
      [
        @id,
        event.user.id,
        entry,
        (event.server.id if server_only)
      ]
    )
    @id += 1
    return "Created entry `#{entry}` on your TODO list. Call `.todo` to see it. "\
      "#{"This entry will only be visible on `#{event.server.name}`." if server_only}"
  end

  # IDs in the database are unique, and will continuously count up. When users look at their TODO
  # list via .todo or .todo --all, they will get them numbered continuously from 1 upwards.
  # This finds the entry that matches the position it's displayed at in the list, and then deletes
  # that. This way, the output is nice, and users don't have to deal with unique IDs.
  def delete_entry(event, id)
    entries = DB.select_rows(:shrk_todo, :user, event.user.id)
    entries.sort_by { |e| e[:id] }.each_with_index do |entry, i|
      if i == id
        DB.delete_value(:shrk_todo, :id, entry[:id])
        return "Successfully deleted entry `#{entry[:entry]}`."
      end
    end
    "Entry with ID #{id + 1} wasn't found. Check your todo list with `.todo` to see which entries exist."
  end

  def show_todo_list(event, show_all)
    embed = Discordrb::Webhooks::Embed.new

    entries = DB.select_rows(:shrk_todo, :user, event.user.id)
    if !show_all && entries.reject { |e| e[:server] && e[:server] != event.server.id }.empty?
      return 'You have no entries on your TODO list, or all entries are hidden on this server.'
    end

    entries.sort_by { |e| e[:id] }.each_with_index do |entry, i|
      unless entry[:server] && entry[:server] != event.server.id && !show_all
        embed.add_field(
          name: "Entry ##{i + 1}:",
          value: entry[:entry]
        )
      end
    end

    embed.colour = 3715045
    embed.title = "Todo list entries for **#{event.user.distinct}**"
    embed.footer = {
      text: show_all ? 'Showing entries from all servers.' : 'Not showing hidden entries.',
      icon_url: event.user.avatar_url
    }

    event.channel.send_embed('', embed)
  end
end
