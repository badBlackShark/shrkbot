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
      class: "flex-none rounded-control border border-danger px-2.5 py-1 text-xs font-semibold text-danger transition-colors hover:bg-danger-soft"
    ) { t(".revoke") }
  end
end
