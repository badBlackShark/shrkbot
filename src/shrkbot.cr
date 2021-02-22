require "yaml"
require "tasker"
require "discordcr"
require "discordcr-plugin"
require "discordcr-middleware"

require "./config"
require "./halts/*"
require "./helpers/*"
require "./plugins/*"
require "./utilities/*"
require "./middlewares/*"
require "./yahoo-finance/*"

module Shrkbot
  # Stuff used across all modules, especially heavily used emojis.
  # Docs say they need to be URI encoded, but now I get an error when I do that. Who even knows.
  CHECKMARK   = "✅" # URI.encode("\u2705")
  CROSSMARK   = "❌" # URI.encode("\u274C")
  TIME_FORMAT = "%A, %d. %B, %Y at %I:%M:%S %p (UTC%:z)" # Please fix

  class Bot
    getter client : Discord::Client
    getter client_id : UInt64
    getter cache : Discord::Cache
    getter db : Db
    delegate run, stop, to: client

    def initialize(token : String, @client_id : UInt64, @db : Db, shard_id, num_shards)
      @client = Discord::Client.new(token: "Bot #{token}", client_id: @client_id,
        shard: {shard_id: shard_id, num_shards: num_shards})
      @cache = Discord::Cache.new(@client)
      @client.cache = @cache
      register_plugins
    end

    def register_plugins
      Discord::Plugin.plugins.each { |plugin| client.register(plugin) }
    end
  end

  class_getter! config : Config

  @@shards = [] of Bot

  def self.bot(guild_id : UInt64? = nil)
    if guild_id
      shard_id = (guild_id >> 22) % config.shard_count
      @@shards[shard_id]
    else
      @@shards[0]
    end
  end

  def self.run(config : Config, db : Db)
    @@config = config

    config.shard_count.times do |id|
      bot = Bot.new(config.token, config.client_id, db, id, config.shard_count)
      @@shards << bot
      spawn { bot.run }
    end
  end

  def self.stop
    @@shards.each do |bot|
      bot.stop
    end
  end
end
