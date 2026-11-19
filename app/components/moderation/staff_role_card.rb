# frozen_string_literal: true

class Components::Moderation::StaffRoleCard < Components::Base
  DEFAULT_COLOR = "#99aab5"
  FIELD = "moderation[staff_role_id]"

  def initialize(server_configuration:, staff_role_id:)
    @config = server_configuration
    @staff_role_id = staff_role_id
  end

  def view_template
    render Components::Card.new do
      render Components::FieldLabel.new do
        plain t(".label")
        render Components::RequiredMarker.new
      end
      render Components::TomSelect.new(
        name: FIELD,
        options: role_options,
        selected: @staff_role_id,
        multiple: false,
        include_blank: true,
        required: true,
        controller_data: {
          tom_select_color_dots_value: true,
          tom_select_placeholder_value: t(".placeholder")
        }
      )
      render Components::FieldHelp.new { t(".help") }
      staff_permission_warning
    end
  end

  private

  def roles
    @roles ||= @config.server_roles.order(:position).to_a
  end

  def role_options
    roles.map do |role|
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

  def staff_permission_warning
    unprivileged_ids = role_ids_without_manage_messages
    render Components::LiveWarning.new(
      fields: [FIELD],
      rule: "includes-any",
      list: unprivileged_ids,
      shown: unprivileged_ids.include?(@staff_role_id.to_s),
      class: "mt-3"
    ) do
      span do
        b(class: "text-warning-text") { t(".staff_permission_warning_bold") }
        whitespace
        plain t(".staff_permission_warning_body")
      end
    end
  end

  def role_ids_without_manage_messages
    @role_ids_without_manage_messages ||= roles.reject(&:manage_messages?).map { |role| role.discord_id.to_s }
  end
end
