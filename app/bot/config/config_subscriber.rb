# frozen_string_literal: true

module Bot
  class ConfigSubscriber
    include WithConnection

    RECONNECT_DELAY = 5

    def initialize(bot)
      @bot = bot
    end

    def start
      Thread.new do
        loop do
          Redis.new(url: Config.redis_url).subscribe(ConfigBus::CHANNEL) do |on|
            on.message do |_channel, payload|
              handle(payload)
            end
          end
        rescue Redis::BaseConnectionError => e
          Rails.logger.warn("[ConfigSubscriber] Redis connection lost (#{e.class}: #{e.message}), retrying in #{RECONNECT_DELAY}s")
          sleep RECONNECT_DELAY
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
      when "commands_sync"
        sync_commands(event[:discord_id])
      when "roles_repost"
        repost_roles(event[:set_id])
      when "roles_post"
        post_roles(event[:set_id])
      when "roles_message_delete"
        delete_message(event[:channel_id], event[:message_id])
      when "roles_menu_remove"
        remove_menu(event[:set_id])
      end
    end

    def sync_commands(discord_id)
      GuildCommandSync.new(bot).sync(discord_id)
    end

    def repost_roles(set_id)
      with_set(set_id, source: "roles_repost") do |set|
        Ops::Roles::Messages::Repost.call(bot:, role_set: set)
      end
    end

    def post_roles(set_id)
      with_set(set_id, source: "roles_post") do |set|
        Ops::Roles::Messages::Post.call(bot:, role_set: set)
      end
    end

    def delete_message(channel_id, message_id)
      report(
        Ops::Roles::Messages::Delete.call(bot:, channel_id:, message_id:),
        source: "roles_message_delete"
      )
    end

    def remove_menu(set_id)
      with_set(set_id, source: "roles_menu_remove") do |set|
        Ops::Roles::Messages::Remove.call(bot:, role_set: set)
      end
    end

    def with_set(set_id, source:)
      set = Roles::Set.find_by(id: set_id)
      return unless set

      report(yield(set), source:)
    end

    def report(result, source:)
      return if result.success?

      Rails.logger.error("[ConfigSubscriber] #{source} failed: #{result.errors.to_sentence}")
    end
  end
end
