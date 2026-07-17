# frozen_string_literal: true

class Servers::ModerationController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  before_action :build_context

  def show
    render Views::Servers::Moderation::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      context: @context
    )
  end

  def update
    return head :not_found unless guild_role?(moderation_params[:staff_role_id])

    result = Ops::Moderation::Configure.call(
      server_configuration: @server_configuration,
      staff_role_id: moderation_params[:staff_role_id],
      enabled: moderation_params[:enabled],
      ping_staff: moderation_params[:ping_staff],
      new_account_age_days: moderation_params[:new_account_age_days]
    )
    respond_with_configuration(result, error_keys: [:enabled, :staff_role_id, :new_account_age_days])
  end

  private

  def moderation_params
    params.expect(moderation: [:staff_role_id, :enabled, :ping_staff, :new_account_age_days])
  end

  def guild_role?(role_id)
    role_id.blank? || @server_configuration.server_roles.exists?(discord_id: role_id)
  end

  def build_context
    @context = Moderation::OverviewContext.new(@server_configuration)
  end
end
