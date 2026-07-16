# frozen_string_literal: true

class Servers::RolesController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include VerifiesGuildChannels

  def show
    render Views::Servers::Roles::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      enabled: plugin_enabled?
    )
  end

  def update
    return head :not_found unless guild_channels?(roles_params[:channel_id], submitted_channel_overrides)

    result = Ops::Roles::Configure.call(
      server_configuration: @server_configuration,
      channel_id: roles_params[:channel_id],
      enabled: roles_params[:enabled],
      role_sets: submitted_sets
    )
    @success = result.success?
    @toast =
      if result.success?
        {level: "notice", message: t("servers.roles.saved")}
      else
        {level: "alert", message: result.errors.to_sentence.presence || t("servers.roles.failed")}
      end

    respond_to do |format|
      format.turbo_stream { render status: result.success? ? :ok : :unprocessable_content }
      format.html { redirect_to server_roles_path(params[:server_id]), **flash_for(result) }
    end
  end

  private

  def submitted_sets
    raw = roles_params[:role_sets]
    list = raw.respond_to?(:values) ? raw.values : Array(raw)
    list.map { |set| set.to_h.symbolize_keys }
  end

  def submitted_channel_overrides
    submitted_sets.filter_map { |set| set[:channel_override] }
  end

  def roles_params
    params.require(:roles).permit(
      :channel_id,
      :enabled,
      role_sets: [:id, :name, :selection_mode, :channel_override, :_destroy, {role_ids: []}]
    )
  end
end
