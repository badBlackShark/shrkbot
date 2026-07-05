# frozen_string_literal: true

module Roles
  class Pick < ComponentHandler
    on :button, custom_id: /\Aroles:pick:/

    def handle
      return unless set && member

      picked = CustomId.parse(event.custom_id)[:role_id]
      return unless set_role_ids.include?(picked)

      diff = Assignment.single(set_role_ids, picked)
      had = member_set_role_ids
      apply(diff)
      event.respond(content: Message.pick_confirmation(set, picked, had), ephemeral: true)
      log_assignment(had, diff)
    end
  end
end
