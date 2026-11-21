# frozen_string_literal: true

class Servers::RolesController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include VerifiesGuildChannels

  def show
    preload_role_sets

    render Views::Servers::Roles::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      enabled: plugin_enabled?
    )
  end

  def update
    return head :not_found unless guild_channels?(roles_params[:channel_id], submitted_channel_overrides)

    result = Ops::Roles::Settings::Update.call(
      server_configuration: @server_configuration,
      channel_id: roles_params[:channel_id],
      enabled: roles_params[:enabled],
      role_sets: submitted_sets
    )
    preload_role_sets if result.success?
    respond_with_save(result)
  end

  private

  def preload_role_sets
    ActiveRecord::Associations::Preloader.new(
      records: [@server_configuration.role_setting],
      associations: {role_sets: :assignable_roles}
    ).call
  end

  def submitted_sets
    @submitted_sets ||= Array(roles_params[:role_sets]&.values).map { |set| set.to_h.symbolize_keys }
  end

  def submitted_channel_overrides
    submitted_sets.filter_map { |set| set[:channel_override] }
  end

  def roles_params
    params.expect(
      roles: [
        :channel_id,
        :enabled,
        role_sets: [[:id, :name, :selection_mode, :channel_override, :_destroy, {role_ids: []}]]
      ]
    )
  end
end
