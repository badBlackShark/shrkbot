# frozen_string_literal: true

class Servers::SpamProtectionController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  before_action :build_context

  def show
    render Views::Servers::SpamProtection::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      context: @context
    )
  end

  def update
    result = Ops::Moderation::SpamProtection::Configure.call(
      server_configuration: @server_configuration,
      channel_threshold: spam_protection_params[:channel_threshold],
      window_seconds: spam_protection_params[:window_seconds],
      similarity: spam_protection_params[:similarity],
      match_symbol_only_messages: spam_protection_params[:match_symbol_only_messages],
      action: spam_protection_params[:action],
      punishment: spam_protection_params[:punishment],
      timeout_seconds: spam_protection_params[:timeout_seconds],
      enabled: spam_protection_params[:enabled]
    )
    activation = result.value
    @enabled = activation.enabled?
    @enable_error = activation.errors[:enabled].first
    @toast = {level: "notice", message: t("servers.spam_protection.saved")} if result.success?

    respond_to do |format|
      format.turbo_stream { render status: result.success? ? :ok : :unprocessable_content }
      format.html { redirect_to server_spam_protection_path(params[:server_id]), **flash_for(result) }
    end
  end

  private

  def spam_protection_params
    params.expect(
      spam_protection: [
        :channel_threshold,
        :window_seconds,
        :similarity,
        :match_symbol_only_messages,
        :action,
        :punishment,
        :timeout_seconds,
        :enabled
      ]
    )
  end

  def build_context
    @context = Moderation::SubPluginContext.new(@server_configuration, :spam_protection)
  end
end
