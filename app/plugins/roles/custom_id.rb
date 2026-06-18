module Roles
  # The component custom_id protocol shared by the message renderers (producers)
  # and the interaction handlers (parser). Format: "roles:<action>:<set_id>[:<role_id>]".
  module CustomId
    PREFIX = "roles"

    module_function

    def manage(set)
      "#{PREFIX}:manage:#{set.id}"
    end

    def pick(set, assignable_role)
      "#{PREFIX}:pick:#{set.id}:#{assignable_role.role_id}"
    end

    def select(set)
      "#{PREFIX}:select:#{set.id}"
    end

    def parse(custom_id)
      _prefix, action, set_id, role_id = custom_id.split(":")
      {action: action&.to_sym, set_id: set_id, role_id: role_id&.to_i}
    end
  end
end
