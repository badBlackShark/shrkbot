class ConfigSubscriber
  include WithConnection

  def initialize(bot)
    @bot = bot
  end

  def start
    Thread.new do
      Redis.new(url: BotConfig.redis_url).subscribe(ConfigBus::CHANNEL) do |on|
        on.message do |_channel, payload|
          handle(payload)
        end
      end
    end
  end

  def handle(payload)
    event = JSON.parse(payload, symbolize_names: true)
    with_connection do
      route(event)
    end
  rescue => e
    Rails.logger.error("[ConfigSubscriber] #{e.class}: #{e.message}")
    OwnerNotifier.report(bot: @bot, error: e, source: "ConfigSubscriber")
  end

  private

  attr_reader :bot

  def route(event)
    case event[:type]
    when "roles_repost"
      repost_roles(event[:set_id])
    end
  end

  def repost_roles(set_id)
    set = Roles::Set.find_by(id: set_id)
    return unless set

    Ops::Roles::Messages::Repost.call(bot: bot, role_set: set)
  end
end
