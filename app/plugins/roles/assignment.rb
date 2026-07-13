# frozen_string_literal: true

module Roles
  module Assignment
    module_function

    def single(set_role_ids, picked_id, held_ids)
      return {add: [], remove: [picked_id]} if held_ids.include?(picked_id)

      {add: [picked_id], remove: set_role_ids - [picked_id]}
    end

    def multi(set_role_ids, selected_ids)
      desired = selected_ids & set_role_ids
      {add: desired, remove: set_role_ids - desired}
    end
  end
end
