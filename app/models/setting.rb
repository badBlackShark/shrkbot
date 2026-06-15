# Global bot-wide key/value flags (distinct from per-server ServerConfiguration).
# Toggle at runtime via console (e.g. `Setting.owner_error_dms = true`) — no
# redeploy — and later via the web UI.
class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  class << self
    def get(key) = find_by(key: key.to_s)&.value

    def set(key, value)
      find_or_initialize_by(key: key.to_s).update!(value: value.to_s)
    end

    # DM the owner exception details when a command/event raises. Default off;
    # flip on for debugging.
    def owner_error_dms? = ActiveModel::Type::Boolean.new.cast(get("owner_error_dms")) == true

    def owner_error_dms=(on)
      set("owner_error_dms", !!on)
    end
  end
end
