# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.string_enum(name, values, validate: true, **options)
    enum(
      name,
      values.to_h { |value| [value.to_sym, value.to_s] },
      validate:,
      **options
    )
  end
end
