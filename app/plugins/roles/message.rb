module Roles
  module Message
    ACTION_ROW = 1
    BUTTON = 2
    PRIMARY = 1

    module_function

    def public_message(set)
      {content: content(set), components: [manage_row(set)]}
    end

    def content(set)
      header = "**#{set.name}**"
      roles = set.assignable_roles.map { |role| [role.emoji, role.label].compact.join(" ") }
      [header, *roles].join("\n")
    end

    def manage_row(set)
      {type: ACTION_ROW, components: [
        {type: BUTTON, style: PRIMARY, label: "Manage Roles", custom_id: CustomId.manage(set)}
      ]}
    end
  end
end
