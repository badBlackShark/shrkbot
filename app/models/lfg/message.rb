# frozen_string_literal: true

module Lfg
  class Message < ApplicationRecord
    self.table_name = "lfg_messages"

    belongs_to :server_configuration

    validates :channel_id, presence: true
    validates :message_id, presence: true, uniqueness: true
  end
end
