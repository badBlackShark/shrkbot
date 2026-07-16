# frozen_string_literal: true

module Roles
  class Pick < ComponentHandler
    on :button, custom_id: /\Aroles:pick:/

    def handle
      return unless set && member

      picked = CustomId.parse(event.custom_id)[:role_id]
      return unless set_role_ids.include?(picked)

      had = member_set_role_ids
      diff = Assignment.single(set_role_ids, picked, had)
      event.defer(ephemeral: true)
      apply(diff)
      event.edit_response(content: Message.pick_confirmation(set, picked, had))
      log_assignment(had, diff)
    end
  end
end
