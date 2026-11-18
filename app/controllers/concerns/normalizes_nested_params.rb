# frozen_string_literal: true

module NormalizesNestedParams
  private

  def symbolized_list(raw)
    list = raw.respond_to?(:values) ? raw.values : Array(raw)
    list.map { |attrs| attrs.to_h.symbolize_keys }
  end
end
