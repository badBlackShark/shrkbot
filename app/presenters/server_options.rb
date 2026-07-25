# frozen_string_literal: true

class ServerOptions
  def initialize(server_configurations)
    @server_configurations = server_configurations
  end

  def options
    @server_configurations.map do |config|
      Components::TomSelect::Option.for(value: config.id, label: label_for(config))
    end
  end

  private

  def label_for(config)
    config.name.presence || config.discord_id.to_s
  end
end
