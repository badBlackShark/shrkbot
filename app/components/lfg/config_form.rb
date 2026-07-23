# frozen_string_literal: true

class Components::Lfg::ConfigForm < Components::Base
  def initialize(server_configuration:, enable_error: nil)
    @config = server_configuration
    @settings = server_configuration.lfg_settings
    @enable_error = enable_error
  end

  def view_template
    div(id: "lfg-config", class: "flex flex-col gap-5", data: {controller: "pingable-roles"}) do
      enable_error_callout
      render Components::Lfg::SetupGuideCard.new
      render Components::Lfg::DefaultsCard.new(settings: @settings, role_options:, channels:)
      render Components::Lfg::PingableRolesCard.new(settings: @settings, context: card_context)
    end
  end

  private

  def enable_error_callout
    return unless @enable_error

    render Components::Callout.new(variant: :danger) { @enable_error }
  end

  def card_context
    @card_context ||= Components::Lfg::PingableRoleFormContext.new(role_options:, channels:)
  end

  def role_options
    @role_options ||= ServerRoleOptions.new(@config).options
  end

  def channels
    @channels ||= ChannelOptions.new(@config).options
  end
end
