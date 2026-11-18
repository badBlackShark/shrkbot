# frozen_string_literal: true

module SecurityUpdates
  Advisory = Data.define(:package, :version, :id, :title, :url, :fixed_in) do
    def key
      [package, id]
    end
  end
end
