class BotSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  class << self
    def get(key)
      find_by(key: key.to_s)&.value
    end

    def set(key, value)
      find_or_initialize_by(key: key.to_s).update!(value: value.to_s)
    end

    def owner_error_dms?
      ActiveModel::Type::Boolean.new.cast(get("owner_error_dms")) == true
    end

    def owner_error_dms=(on)
      set("owner_error_dms", !!on)
    end
  end
end
