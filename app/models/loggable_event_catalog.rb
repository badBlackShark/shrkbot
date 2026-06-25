# frozen_string_literal: true

class LoggableEventCatalog
  Definition = Data.define(:plugin, :event) do
    def key
      "#{plugin}.#{event}"
    end
  end

  DEFINITIONS = [
    Definition.new(plugin: :roles, event: :role_gained),
    Definition.new(plugin: :roles, event: :role_lost)
  ].freeze

  def self.all
    DEFINITIONS
  end

  def self.grouped_by_plugin
    DEFINITIONS.group_by(&:plugin)
  end
end
