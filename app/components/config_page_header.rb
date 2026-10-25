# frozen_string_literal: true

module Components
  ConfigPageHeader = Data.define(:icon, :title, :description, :badge, :media, :aside) do
    def initialize(icon:, title:, description:, badge: nil, media: nil, aside: nil)
      super
    end
  end
end
