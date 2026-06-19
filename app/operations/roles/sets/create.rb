module Ops
  module Roles
    module Sets
      class Create < ApplicationOperation
        receives :server_configuration, :name, :selection_mode
        receives :channel_override, optional: true

        def call
          setting = server_configuration.role_setting || server_configuration.create_role_setting!
          set = setting.role_sets.create!(
            name: name,
            selection_mode: selection_mode,
            channel_override: channel_override,
            position: next_position(setting)
          )
          ok(set)
        end

        private

        def next_position(setting)
          (setting.role_sets.maximum(:position) || -1) + 1
        end
      end
    end
  end
end
