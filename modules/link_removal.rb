require 'rufus-scheduler'

# Removes links that staff can set, mutes users that posts them.
module LinkRemoval
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer
  extend self

  # Server => links
  @prohibited = {}
  @permitted = {}

  @scheduler = Rufus::Scheduler.new

  def init
    DB.create_table(
      'shrk_link_removal',
      server: :bigint,
      link: :text,
      duration: String
    )

    SHRK.servers.each_value { |server| update_prohibited(server.id) }
  end

  message do |event|
    next if SHRK.permission?(event.user, 1, event.server) || @permitted[event.user.id]
    text = event.message.content.gsub(/(\{|\[|\()?(dot|\.)(\]|\}|\))?/i, '.').downcase

    if (duration = contains_prohibited?(event.server.id, text))
      event.message.delete
      Moderation.mute(event, [event.user], duration, 'Posted a prohibited link.')
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'prohibit <link> <duration> <--ignore-whitespace>',
    description: 'Prohibits linking to the specified site. Keep this as general as possible for best results. '\
                 'Duration defaults to 2h. The flag is optional. When enabled, the bot will still recognize the '\
                 'link, even if there\'s whitespace in it. Beware of false positives.'
  }
  command :prohibit, attrs do |event, link, *args|
    next 'Not a link.' unless link?(link)
    # Makes the URL simpler, so even non-clickable links will be caught.
    link = link.downcase.gsub(/https?:\/\/(www.)?/, '')
    duration = args.select { |a| a =~ /^((\d+)[smhdwMy]{1})+$/ }
    duration = '2h' if duration.empty?
    ignore_whitespace = args.include?('--ignore-whitespace')

    if contains_prohibited?(event.server.id, link, strict: false)
      "Linking to `#{link}` is already prohibited."
    else
      event.respond "Linking to `#{link}` is now prohibited."
      link = link.split('').join('\s*') if ignore_whitespace
      DB.insert_row(:shrk_link_removal, [event.server.id, link, duration])
      update_prohibited(event.server.id)
      nil
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'allow <link>',
    description: 'Now allows linking to this site again.'
  }
  command :allow, attrs do |event, *args|
    link = args.join(' ').gsub(/https?:\/\/(www.)?/, '')
    if (entries = @prohibited[event.server.id].select { |entry| entry[:link].gsub(/\\s\*/, '').include?(link) })
      entries.each do |entry|
        DB.delete_value(:shrk_link_removal, :link, entry[:link])
      end
      update_prohibited(event.server.id)
      "Linking to `#{link}` is no longer prohibited."
    else
      "Linking to `#{link}` isn't prohibited."
    end
  end

  attrs = {
    usage: 'prohibited',
    description: 'Lists all prohibited sites.'
  }
  command :prohibited, attrs do |event|
    embed = Discordrb::Webhooks::Embed.new
    field_value = ''

    @prohibited[event.server.id].map { |entry| entry[:link] }.sort.each do |link|
      field_value << "• `#{link.gsub(/\\s\*/, '')}`\n"
    end

    next 'There are no prohibited links.' if field_value.empty?

    embed.add_field(
      name: 'Prohibited links:',
      value: field_value
    )
    embed.color = 16711680
    embed.footer = {
      text: 'All sites you aren\'t allowed to link.',
      icon_url: SHRK.profile.avatar_url
    }
    embed.timestamp = Time.now

    event.channel.send_embed('', embed)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'permit <userMentions>',
    description: 'Allows all mentioned users to send prohibited links for 30s.'
  }
  command :permit, attrs do |event|
    users = event.message.mentions

    users.each do |user|
      @permitted[user.id] = true
      @scheduler.in '30s' do
        @permitted.delete(user.id)
      end
    end
    "`#{users.map(&:distinct).join('`, `')}` may send prohibited links for 30s."
  end

  server_create do |event|
    update_prohibited(event.server.id)
  end

  private

  def link?(string)
    string =~ /(https?:\/\/)?(www\.)?[ a-zA-Z0-9@:%._\+~#=-]{2,256}((\.[a-z]{2,6})|:)([ a-zA-Z0-9@:%._\+.~#?&\/=-]*)/
  end

  def contains_prohibited?(id, message, strict: true)
    if strict
      @prohibited[id].each do |entry|
        return entry[:duration] if message.match?(Regexp.new(entry[:link]))
      end
      false
    else
      return @prohibited[id].find { |entry| message.include?(entry[:link].gsub(/\\s\*/, '')) }
    end
  end

  def update_prohibited(server_id)
    @prohibited[server_id] = DB.select_rows(:shrk_link_removal, :server, server_id)
    @prohibited[server_id] ||= {}
  end
end
