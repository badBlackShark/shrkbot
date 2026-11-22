# frozen_string_literal: true

module Feeds
  def self.sources
    [Steam, Twitch]
  end

  def self.source(key)
    sources.find { |source| source.key == key } || raise(KeyError, "no Feeds source for #{key.inspect}")
  end

  def self.sources_for_plugin(plugin_key)
    sources.select { |source| source.plugin_key == plugin_key }
  end

  def self.source_for_watcher(watcher)
    sources.find { |source| source.watchers.include?(watcher) } || raise(KeyError, "no Feeds source for #{watcher.inspect}")
  end

  def self.event_key(event_type)
    event_type.demodulize.underscore
  end
end
