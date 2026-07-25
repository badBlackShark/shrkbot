# frozen_string_literal: true

class Components::Admin::BespokePluginCard < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(definition:, grants:, servers:)
    @definition = definition
    @grants = grants
    @servers = servers
  end

  def view_template
    render Components::Card.new do
      header
      grant_list
      ungranted_servers.empty? ? all_granted_note : grant_form
    end
  end

  private

  def header
    p(class: "text-sm font-semibold") { @definition.name }
    p(class: "mt-0.5 text-sm text-text-secondary") { @definition.description }
  end

  def grant_list
    p(class: "mt-4 text-[11px] font-semibold uppercase tracking-widest text-eyebrow") { t(".granted") }
    return p(class: "mt-1 text-sm text-text-muted") { t(".none") } if @grants.empty?

    div(class: "mt-1") do
      @grants.each { |grant| render Components::Admin::BespokePluginGrantRow.new(grant:) }
    end
  end

  def all_granted_note
    p(class: "mt-4 text-sm text-text-muted") { t(".all_granted") }
  end

  def grant_form
    form_with(url: admin_bespoke_plugin_grants_path, method: :post, class: "mt-4 flex items-end gap-2") do
      input(type: "hidden", name: "plugin_key", value: @definition.key.to_s)
      div(class: "flex-1") do
        render Components::TomSelect.new(
          name: "server_configuration_id",
          options: server_options,
          include_blank: true,
          controller_data: {tom_select_placeholder_value: t(".placeholder")}
        )
      end
      render Components::Button.new(label: t(".grant"), type: "submit")
    end
  end

  def server_options
    ungranted_servers.map do |config|
      Components::TomSelect::Option.for(value: config.id, label: config.name.presence || config.discord_id.to_s)
    end
  end

  def ungranted_servers
    @ungranted_servers ||= @servers.reject { |config| granted_ids.include?(config.id) }
  end

  def granted_ids
    @granted_ids ||= @grants.map(&:server_configuration_id).to_set
  end
end
