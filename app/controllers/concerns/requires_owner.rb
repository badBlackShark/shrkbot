# frozen_string_literal: true

module RequiresOwner
  extend ActiveSupport::Concern

  included do
    before_action :require_owner
  end

  private

  def require_owner
    redirect_to servers_path, alert: t("admin.owner_only") unless current_user.owner?
  end
end
