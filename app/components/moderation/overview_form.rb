# frozen_string_literal: true

class Components::Moderation::OverviewForm < Components::Base
  def initialize(server_configuration:, context:, enable_error: nil)
    @config = server_configuration
    @context = context
    @enable_error = enable_error
  end

  def view_template
    div(id: "moderation-config", class: "flex flex-col gap-5") do
      enable_error_callout
      render Components::Moderation::StaffRoleCard.new(
        server_configuration: @config,
        staff_role_id: @context.staff_role_id,
        missing: !@context.staff_role_present?,
        permission_warning: @context.permission_warning?,
        staff_permission_warning: @context.staff_permission_warning?
      )
      render Components::Moderation::SubPluginDirectory.new(
        server_configuration: @config,
        context: @context
      )
      render Components::Moderation::MatchingExplainer.new
    end
  end

  private

  def enable_error_callout
    return unless @enable_error

    render Components::Callout.new(variant: :danger) { @enable_error }
  end
end
