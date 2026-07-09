# frozen_string_literal: true

class Components::Moderation::StaffRoleCard < Components::Base
  DEFAULT_COLOR = "#99aab5"

  def initialize(server_configuration:, staff_role_id:, missing:, permission_warning:)
    @config = server_configuration
    @staff_role_id = staff_role_id
    @missing = missing
    @permission_warning = permission_warning
  end

  def view_template
    render Components::Card.new do
      label(class: "block text-sm font-semibold mb-1.5") do
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
      missing_warning if @missing
      p(class: "mt-1.5 text-xs text-text-muted") { t(".help") } unless @missing
      permission_warning_callout if @permission_warning
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

  def missing_warning
    p(class: "mt-1.5 flex items-center gap-1 text-xs font-medium text-warning") do
      render Components::Icon.new("warning", class: "size-3.5")
      span { t(".missing_warning") }
    end
  end

  def permission_warning_callout
    div(class: "mt-3") do
      render Components::Callout.new(variant: :warning) do
        plain ""
        span do
          b(class: "text-warning") { t(".permission_warning_bold") }
          whitespace
          plain t(".permission_warning_body")
        end
      end
    end
  end
end
