# frozen_string_literal: true

class AccountsController < ApplicationController
  def show
    render Views::Accounts::Show.new(
      user: current_user,
      reminder_count: ::Reminders::Reminder.for_user(current_user.discord_id).count
    )
  end

  def destroy
    Ops::Users::Destroy.call(user: current_user)
    reset_session
    redirect_to root_path, notice: t("accounts.deleted")
  end
end
