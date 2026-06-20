module Roles
  class Pick < ComponentHandler
    on :button, custom_id: /\Aroles:pick:/

    def handle
      return unless set && member

      picked = CustomId.parse(event.custom_id)[:role_id]
      return unless set_role_ids.include?(picked)

      apply(Assignment.single(set_role_ids, picked))
      event.respond(content: Message.selection_summary(set, [picked]), ephemeral: true)
    end
  end
end
