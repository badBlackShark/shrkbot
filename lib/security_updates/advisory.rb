# frozen_string_literal: true

module SecurityUpdates
  Advisory = Data.define(:package, :version, :id, :title, :url, :fixed_in) do
    def key
      [package, id, title]
    end

    def fixable?
      fixed_in.any?
    end
  end
end
