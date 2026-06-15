# String primary keys shaped like "srv_<uuid>" — a 3-letter per-table prefix
# makes IDs identifiable at a glance. Each model declares: `id_prefix "srv"`.
module PrefixedId
  extend ActiveSupport::Concern

  included do
    before_create { self.id = "#{self.class.id_prefix}_#{SecureRandom.uuid}" if id.blank? }
  end

  class_methods do
    def id_prefix(value = nil)
      @id_prefix = value if value
      @id_prefix
    end
  end
end
