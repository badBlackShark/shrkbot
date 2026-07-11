# frozen_string_literal: true

class Views::Accounts::Show < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(user:, reminder_count:)
    @user = user
    @reminder_count = reminder_count
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      div(class: "mx-auto max-w-2xl px-6 py-10") do
        render Components::PageHeading.new(title: t(".title"), subtitle: t(".subtitle"))
        data_card
        danger_card
      end
    end
  end

  private

  def data_card
    render Components::Card.new(class: "mb-6 flex flex-col gap-4") do
      div(class: "flex items-center gap-4") do
        render Components::UserAvatar.new(user: @user, size: :lg)
        div do
          p(class: "font-semibold") { @user.display_name }
          p(class: "text-sm text-text-secondary") { @user.username }
          p(class: "text-sm text-text-secondary") { @user.discord_id.to_s }
        end
      end
      p(class: "text-sm text-text-secondary") { t(".reminders", count: @reminder_count) }
    end
  end

  def danger_card
    render Components::Card.new do
      h2(class: "mb-2 font-semibold") { t(".danger_title") }
      p(class: "mb-4 text-sm text-text-secondary") { t(".danger_body") }
      button_to(
        account_path,
        method: :delete,
        data: {turbo_confirm: t(".confirm")},
        class: "rounded-md border border-danger px-4 py-2 text-sm font-semibold text-danger transition-colors hover:bg-danger-soft"
      ) { t(".button") }
    end
  end
end
