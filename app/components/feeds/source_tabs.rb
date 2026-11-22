# frozen_string_literal: true

class Components::Feeds::SourceTabs < Components::Base
  def initialize(server_configuration:, plugin_key:, selected: nil)
    @config = server_configuration
    @plugin_key = plugin_key
    @selected = selected
  end

  def view_template
    render Components::ConfigSections.new(key: @plugin_key.to_s) do
      if sources.one?
        render Components::Feeds::SubscriptionList.new(server_configuration: @config, source: sources.first)
      else
        tabs
      end
    end
  end

  private

  def tabs
    div(class: "flex flex-col gap-5", data: {controller: "option-panels"}) do
      div(class: "max-w-md") do
        render Components::SegmentedControl.new(
          name: "tab",
          value: current.key.to_s,
          label: t(".label"),
          options: sources.map { |source| {value: source.key.to_s, label: t(".#{source.key}")} },
          input_data: {action: "input->option-panels#show"}
        )
      end
      sources.each { |source| panel(source) }
    end
  end

  def panel(source)
    div(hidden: source != current, data: {option_panels_target: "panel", value: source.key.to_s}) do
      render Components::Feeds::SubscriptionList.new(server_configuration: @config, source:)
    end
  end

  def current
    sources.find { |source| source.key.to_s == @selected } || sources.first
  end

  def sources
    @sources ||= ::Feeds.sources_for_plugin(@plugin_key)
  end
end
