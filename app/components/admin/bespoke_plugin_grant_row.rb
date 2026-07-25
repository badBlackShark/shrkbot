# frozen_string_literal: true

class Components::Admin::BespokePluginGrantRow < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(grant:)
    @grant = grant
  end

  def view_template
    div(class: "flex items-center justify-between gap-3 border-b border-border-subtle py-2 last:border-b-0") do
      span(class: "truncate text-sm") { server_label }
      revoke_button
    end
  end

  private

  def server_label
    config = @grant.server_configuration
    config.name.presence || config.discord_id.to_s
  end

  def revoke_button
    button_to(
      admin_bespoke_plugin_grant_path(@grant),
      method: :delete,
      data: {turbo_confirm: t(".confirm")},
      class: Components::Button.css(variant: :danger_outline, size: :sm, extra: "flex-none")
    ) { t(".revoke") }
  end
end
