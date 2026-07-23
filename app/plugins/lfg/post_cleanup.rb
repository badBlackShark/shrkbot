# frozen_string_literal: true

module Lfg
  module PostCleanup
    module_function

    def close(record, message_id, &deleter)
      if record
        record.follow_up_ids.each(&deleter)
        Ops::Lfg::Message::Destroy.call(message: record)
      end
      deleter.call(message_id)
    end
  end
end
