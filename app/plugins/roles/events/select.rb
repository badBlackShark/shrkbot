module Roles
  class Select < ComponentHandler
    on :string_select, custom_id: /\Aroles:select:/

    def handle
      return unless set && member

      selected = event.values.map(&:to_i)
      active = selected & set_role_ids
      apply(Assignment.multi(set_role_ids, selected), active)
      update(Message.multi_picker(set, active))
    end
  end
end
