# frozen_string_literal: true

module Feeds
  def self.sources
    [Steam]
  end

  def self.find_source(plugin_key)
    sources.find { |source| source.plugin_key == plugin_key }
  end

  def self.source(plugin_key)
    find_source(plugin_key) || raise(KeyError, "no Feeds source for #{plugin_key.inspect}")
  end

  def self.source_for_watcher(watcher)
    sources.find { |source| source.watchers.include?(watcher) } || raise(KeyError, "no Feeds source for #{watcher.inspect}")
  end

  def self.event_key(event_type)
    event_type.demodulize.underscore
  end
end
