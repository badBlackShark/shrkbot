# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module Plugins
      class Lock < ApplicationOperation
        self.transactional = false

        receives :server_configuration

        def call
          ::ServerConfiguration.lock("FOR NO KEY UPDATE").where(id: server_configuration.id).pick(:id)
          ok
        end
      end
    end
  end
end
