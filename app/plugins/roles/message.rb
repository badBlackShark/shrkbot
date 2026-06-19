module Roles
  module Message
    ACTION_ROW = 1
    BUTTON = 2
    STRING_SELECT = 3
    PRIMARY = 1
    SECONDARY = 2
    BUTTONS_PER_ROW = 5

    module_function

    def public_message(set)
      if set.selection_mode == "single"
        {content: single_content(set), components: button_rows(role_buttons(set))}
      else
        {content: content(set), components: [manage_row(set)]}
      end
    end

    def content(set)
      header = "**#{set.name}**"
      roles = set.assignable_roles.map { |role| label(role) }
      [header, *roles].join("\n")
    end

    def single_content(set)
      "**#{set.name}**\nPick a role below. You can only have one, so choosing a role replaces your current one."
    end

    def role_buttons(set)
      set.assignable_roles.map do |role|
        {type: BUTTON, style: SECONDARY, label: label(role), custom_id: CustomId.pick(set, role)}
      end
    end

    def multi_picker(set, active_role_ids)
      options = set.assignable_roles.map do |role|
        option = {label: role.label, value: role.role_id.to_s}
        option[:description] = role.description if role.description.present?
        option[:default] = true if active_role_ids.include?(role.role_id)
        option
      end
      select = {
        type: STRING_SELECT,
        custom_id: CustomId.select(set),
        min_values: 0,
        max_values: options.size,
        options: options
      }
      {content: picker_content(set), components: [{type: ACTION_ROW, components: [select]}]}
    end

    def selection_summary(set, active_role_ids)
      chosen = set.assignable_roles
        .select { |role| active_role_ids.include?(role.role_id) }
        .map(&:label)
      "**#{set.name}**: #{chosen.any? ? chosen.join(", ") : "none"}"
    end

    def manage_row(set)
      {type: ACTION_ROW, components: [
        {type: BUTTON, style: PRIMARY, label: "Manage Roles", custom_id: CustomId.manage(set)}
      ]}
    end

    def label(role)
      [role.emoji, role.label].compact.join(" ")
    end

    def picker_content(set)
      "**#{set.name}** — choose your roles."
    end

    def button_rows(buttons)
      buttons.each_slice(BUTTONS_PER_ROW).map { |row| {type: ACTION_ROW, components: row} }
    end

    private_class_method :content, :single_content, :role_buttons, :manage_row, :label, :picker_content, :button_rows
  end
end
