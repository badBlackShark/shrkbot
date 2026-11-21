# frozen_string_literal: true

class Components::Moderation::OverviewForm < Components::Base
  def initialize(server_configuration:, context:)
    @config = server_configuration
    @context = context
  end

  def view_template
    render Components::ConfigSections.new(key: "moderation") do
      render Components::Moderation::StaffRoleCard.new(
        server_configuration: @config,
        staff_role_id: @context.staff_role_id
      )
      render Components::Moderation::StaffPingCard.new(ping_staff: @context.ping_staff)
      render Components::Moderation::AccountAgeCard.new(
        new_account_age_days: @context.new_account_age_days
      )
      render Components::SubPluginDirectory.new(
        server_configuration: @config,
        parent: :moderation,
        heading: t(".protections")
      )
      render Components::Moderation::MatchingExplainer.new
    end
  end
end
