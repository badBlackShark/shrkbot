# frozen_string_literal: true

class Views::Servers::Integrations::Show < Views::Servers::GroupShow
  private

  def plugin_key
    :integrations
  end

  def body
    render Components::Integrations::Overview.new(server_configuration: @config)
  end
end
