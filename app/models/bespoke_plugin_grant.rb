# frozen_string_literal: true

class BespokePluginGrant < ApplicationRecord
  belongs_to :server_configuration

  validates :plugin_key, presence: true, uniqueness: {scope: :server_configuration_id}

  def self.granted_keys(server_configuration)
    where(server_configuration:).pluck(:plugin_key).map(&:to_sym).to_set
  end

  def self.grouped_by_plugin_key
    includes(:server_configuration).group_by { |grant| grant.plugin_key.to_sym }
  end
end
