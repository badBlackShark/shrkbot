# frozen_string_literal: true

module Lfg
  module CustomId
    PREFIX = "lfg"

    module_function

    def join(creator_id, start_ts)
      "#{PREFIX}:join:#{creator_id}:#{start_ts}"
    end

    def done(creator_id, start_ts)
      "#{PREFIX}:done:#{creator_id}:#{start_ts}"
    end

    def parse(custom_id)
      _prefix, action, creator_id, start_ts = custom_id.split(":")
      {action: action&.to_sym, creator_id: creator_id&.to_i, start_ts: start_ts&.to_i}
    end
  end
end
