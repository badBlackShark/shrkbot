# frozen_string_literal: true

class Views::Servers::Moderation::SubPluginShow < Views::Servers::SubPluginShow
  def initialize(server_configuration:, user:, context:)
    super(server_configuration:, user:)
    @context = context
  end

  private

  def body
    render form
  end

  def gate
    return if fix_locations.empty?

    {
      type: :prereq,
      title: t("views.servers.moderation.sub_plugin_show.prerequisites.title", plugin: definition.name),
      steps: fix_locations.map { |key| prerequisite_step(key) }
    }
  end

  def toggle
    return super if enabled? || fix_locations.empty?

    super.merge(locked: true, reason: t("components.plugin_row.needs_setup_hint"))
  end

  def fix_locations
    @fix_locations ||= unmet_fix_locations
  end

  def unmet_fix_locations
    blockers = definition.blockers(@config)
    [
      (definition.requires_plugin if blockers.include?(:requires_plugin)),
      (definition.parent if blockers.include?(:prerequisite))
    ].compact
  end

  def prerequisite_step(key)
    Components::PrereqGate::Step.new(
      message: t("views.servers.moderation.sub_plugin_show.prerequisites.#{key}.message"),
      cta_label: t("views.servers.moderation.sub_plugin_show.prerequisites.#{key}.cta"),
      cta_href: PluginPaths.for(@config, key)
    )
  end

  def definition
    PluginCatalog.find(plugin_key)
  end
end
