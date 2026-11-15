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

  def prerequisites
    return if unmet_steps.empty?

    Components::PrerequisiteSteps.new(
      title: prerequisites_title,
      steps: unmet_steps
    )
  end

  def prerequisites_title
    return t("views.servers.moderation.sub_plugin_show.prerequisites.title_enabled") if enabled?

    t("views.servers.moderation.sub_plugin_show.prerequisites.title", plugin: definition.name)
  end

  def toggle
    return super if enabled? || unmet_steps.empty?

    super.merge(locked: true, reason: t("components.plugin_row.needs_setup_hint"))
  end

  def unmet_steps
    @unmet_steps ||= build_unmet_steps
  end

  def build_unmet_steps
    blockers = definition.blockers(@config)
    steps = ::Moderation::SetupSteps.new(@config)
    [
      (steps.logging if blockers.include?(:requires_plugin)),
      (steps.staff_role if blockers.include?(:prerequisite))
    ].compact
  end

  def definition
    PluginCatalog.find(plugin_key)
  end
end
