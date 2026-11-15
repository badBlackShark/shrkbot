# frozen_string_literal: true

module Moderation
  class SetupSteps
    STEP_PAGES = {logging_channel: :logging, logging_disabled: :logging, staff_role: :moderation}.freeze

    def initialize(server_configuration)
      @config = server_configuration
    end

    def logging
      step(@config.logging_settings.channel_id.present? ? :logging_disabled : :logging_channel)
    end

    def staff_role
      step(:staff_role)
    end

    private

    def step(key)
      Components::PrerequisiteSteps::Step.new(
        message: I18n.t("views.servers.moderation.sub_plugin_show.prerequisites.#{key}.message"),
        cta_label: I18n.t("views.servers.moderation.sub_plugin_show.prerequisites.#{key}.cta"),
        cta_href: PluginPaths.for(@config, STEP_PAGES.fetch(key))
      )
    end
  end
end
