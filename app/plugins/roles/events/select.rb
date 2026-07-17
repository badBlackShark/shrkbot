# frozen_string_literal: true

module Roles
  class Select < ComponentHandler
    on :string_select, custom_id: /\Aroles:select:/

    def handle
      return unless set && member

      selected = event.values.map(&:to_i)
      diff = Assignment.multi(set_role_ids, selected)
      had = member_set_role_ids
      event.defer_update
      apply(diff)
      picker = Message.multi_picker(set, selected & set_role_ids)
      event.edit_response(components: picker[:components], has_components: true)
      log_assignment(had, diff)
    end
  end
end
