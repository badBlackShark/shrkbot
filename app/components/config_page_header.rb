# frozen_string_literal: true

module Components
  ConfigPageHeader = Data.define(:icon, :title, :description, :badge, :banner, :aside) do
    def initialize(title:, icon: nil, description: nil, badge: nil, banner: nil, aside: nil)
      super
    end
  end
end
