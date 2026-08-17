# frozen_string_literal: true

module EstablishesPreviewIdentity
  extend ActiveSupport::Concern

  included do
    prepend_before_action :establish_preview_identity
  end

  private

  def establish_preview_identity
    return unless params[:preview].present?
    return if current_user

    session[:user_id] = Ops::User::Previews::Ensure.call.value.id
    session[:preview_identity] = true
  end
end
