module Roles
  class Select < ComponentHandler
    on :string_select, custom_id: /\Aroles:select:/

    def handle
      return unless set && member

      selected = event.values.map(&:to_i)
      apply(Assignment.multi(set_role_ids, selected))
      update(Message.multi_picker(set, selected & set_role_ids))
    end
  end
end
