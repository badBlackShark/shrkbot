# frozen_string_literal: true

class Servers::LfgController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include VerifiesGuildChannels

  def show
    render Views::Servers::Lfg::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      enabled: plugin_enabled?
    )
  end

  def update
    return head :not_found unless guild_roles?(submitted_role_ids) && guild_channels?(submitted_channel_ids)

    result = Ops::Lfg::Configure.call(
      server_configuration: @server_configuration,
      enabled: lfg_params[:enabled],
      cooldown_seconds: lfg_params[:cooldown_seconds],
      post_lifetime_minutes: lfg_params[:post_lifetime_minutes],
      default_min_membership_days: lfg_params[:default_min_membership_days],
      default_required_role_ids: Array(lfg_params[:default_required_role_ids]),
      default_excluded_role_ids: Array(lfg_params[:default_excluded_role_ids]),
      allowed_channel_ids: Array(lfg_params[:allowed_channel_ids]),
      pingable_roles: submitted_pingable_roles
    )
    respond_with_configuration(
      result,
      error_keys: [:enabled, :cooldown_seconds, :post_lifetime_minutes, :default_min_membership_days]
    )
  end

  private

  def submitted_pingable_roles
    raw = lfg_params[:pingable_roles]
    list = raw.respond_to?(:values) ? raw.values : Array(raw)
    list.map { |attrs| attrs.to_h.symbolize_keys }
  end

  def submitted_role_ids
    feature = Array(lfg_params[:default_required_role_ids]) + Array(lfg_params[:default_excluded_role_ids])
    nested = submitted_pingable_roles.flat_map do |attrs|
      [attrs[:role_id], *Array(attrs[:required_role_ids]), *Array(attrs[:excluded_role_ids])]
    end
    feature + nested
  end

  def submitted_channel_ids
    feature = Array(lfg_params[:allowed_channel_ids])
    nested = submitted_pingable_roles.flat_map { |attrs| Array(attrs[:allowed_channel_ids]) }
    feature + nested
  end

  def guild_roles?(role_ids)
    ids = role_ids.compact_blank.map(&:to_s).uniq
    ids.empty? || @server_configuration.server_roles.where(discord_id: ids).count == ids.size
  end

  def lfg_params
    params.require(:lfg).permit(
      :enabled,
      :cooldown_seconds,
      :post_lifetime_minutes,
      :default_min_membership_days,
      default_required_role_ids: [],
      default_excluded_role_ids: [],
      allowed_channel_ids: [],
      pingable_roles: [
        :role_id,
        :min_membership_days,
        {required_role_ids: [], excluded_role_ids: [], allowed_channel_ids: []}
      ]
    )
  end
end
