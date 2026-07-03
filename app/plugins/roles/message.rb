# frozen_string_literal: true

module Roles
  module Message
    SECTION = 9
    ACTION_ROW = 1
    BUTTON = 2
    STRING_SELECT = 3
    PRIMARY = 1
    SECONDARY = 2
    BUTTONS_PER_ROW = 5
    UNKNOWN_ROLE = "Unknown role"

    module_function

    def public_message(set)
      blocks =
        if set.selection_mode == "single"
          [Discord::Components.text(single_content(set)), Discord::Components.separator, *button_rows(role_buttons(set))]
        else
          [Discord::Components.text(multi_content(set)), Discord::Components.separator, manage_section(set)]
        end
      Discord::Components.container(blocks)
    end

    def multi_picker(set, active_role_ids)
      Discord::Components.container(
        [Discord::Components.text(picker_content(set)), action_row([role_select(set, active_role_ids)])]
      )
    end

    def selection_summary(set, active_role_ids)
      names = role_names(set)
      chosen = set.assignable_roles
        .select { |role| active_role_ids.include?(role.role_id) }
        .map { |role| names[role.role_id] || UNKNOWN_ROLE }
      "**#{set.name}**: #{chosen.any? ? chosen.join(", ") : "none"}"
    end

    def manage_section(set)
      {
        type: SECTION,
        components: [Discord::Components.text("-# Click this button to edit your roles ->")],
        accessory: manage_button(set)
      }
    end

    def action_row(components)
      {type: ACTION_ROW, components:}
    end

    def single_content(set)
      "### #{set.name}\nPick a role below — you can only have one, so choosing a role replaces your current one."
    end

    def multi_content(set)
      names = role_names(set)
      roles = set.assignable_roles.map { |role| "- **#{role_label(role, names)}**" }.join("\n")
      "### #{set.name}\nSelect all roles that apply. You will have the following options:\n#{roles}"
    end

    def picker_content(set)
      "### #{set.name}\nSelect all roles that apply."
    end

    def role_buttons(set)
      names = role_names(set)
      set.assignable_roles.map do |role|
        {type: BUTTON, style: SECONDARY, label: role_label(role, names), custom_id: CustomId.pick(set, role)}
      end
    end

    def role_select(set, active_role_ids)
      names = role_names(set)
      options = set.assignable_roles.map do |role|
        option = {label: names[role.role_id] || UNKNOWN_ROLE, value: role.role_id.to_s}
        option[:description] = role.description if role.description.present?
        option[:default] = true if active_role_ids.include?(role.role_id)
        option
      end
      {
        type: STRING_SELECT,
        custom_id: CustomId.select(set),
        min_values: 0,
        max_values: options.size,
        options:
      }
    end

    def manage_button(set)
      {type: BUTTON, style: PRIMARY, label: "Manage Roles", custom_id: CustomId.manage(set)}
    end

    def button_rows(buttons)
      buttons.each_slice(BUTTONS_PER_ROW).map { |row| action_row(row) }
    end

    def role_names(set)
      set.role_setting.server_configuration.server_roles
        .where(discord_id: set.assignable_roles.map(&:role_id))
        .pluck(:discord_id, :name)
        .to_h
    end

    def role_label(role, names)
      [role.emoji, names[role.role_id] || UNKNOWN_ROLE].compact.join(" ")
    end

    private_class_method :manage_section, :action_row,
      :single_content, :multi_content, :picker_content,
      :role_buttons, :role_select, :manage_button, :button_rows, :role_names, :role_label
  end
end
