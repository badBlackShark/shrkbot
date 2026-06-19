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
      {content: content(set), components: [manage_row(set)]}
    end

    def content(set)
      header = "**#{set.name}**"
      roles = set.assignable_roles.map { |role| label(role) }
      [header, *roles].join("\n")
    end

    def single_picker(set, active_role_ids)
      buttons = set.assignable_roles.map do |role|
        {
          type: BUTTON,
          style: active_role_ids.include?(role.role_id) ? PRIMARY : SECONDARY,
          label: label(role),
          custom_id: CustomId.pick(set, role)
        }
      end
      {content: picker_content(set), components: button_rows(buttons)}
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
  end
end
