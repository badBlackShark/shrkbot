# frozen_string_literal: true

module Components
  ConfigPageHeader = Data.define(:icon, :title, :description, :badge) do
    def initialize(icon:, title:, description:, badge: nil)
      super
    end
  end
end
