# frozen_string_literal: true

class Components::Moderation::StaffRoleCard < Components::Base
  DEFAULT_COLOR = "#99aab5"

  def initialize(server_configuration:, staff_role_id:, permission_warning:, staff_permission_warning:)
    @config = server_configuration
    @staff_role_id = staff_role_id
    @permission_warning = permission_warning
    @staff_permission_warning = staff_permission_warning
  end

  def view_template
    render Components::Card.new do
      render Components::FieldLabel.new do
        plain t(".label")
        span(class: "ml-1 text-xs font-semibold text-danger") { "*" }
      end
      render Components::TomSelect.new(
        name: "moderation[staff_role_id]",
        options: role_options,
        selected: @staff_role_id,
        multiple: false,
        include_blank: true,
        controller_data: {
          tom_select_color_dots_value: true,
          tom_select_placeholder_value: t(".placeholder")
        }
      )
      render Components::FieldHelp.new { t(".help") }
      warning_callout(t(".permission_warning_bold"), t(".permission_warning_body")) if @permission_warning
      warning_callout(t(".staff_permission_warning_bold"), t(".staff_permission_warning_body")) if @staff_permission_warning
    end
  end

  private

  def role_options
    @config.server_roles.order(:position).map do |role|
      Components::TomSelect::Option.for(
        value: role.discord_id,
        label: role.name,
        color: color_hex(role.color)
      )
    end
  end

  def color_hex(color)
    return DEFAULT_COLOR if color.zero?

    "#%06x" % (color & 0xFFFFFF)
  end

  def warning_callout(bold, body)
    div(class: "mt-3") do
      render Components::Callout.new(variant: :warning) do
        plain ""
        span do
          b(class: "text-warning") { bold }
          whitespace
          plain body
        end
      end
    end
  end
end
