# frozen_string_literal: true

class Views::Accounts::Show < Views::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ImageTag
  include Components::Initials

  def initialize(user:, reminder_count:)
    @user = user
    @reminder_count = reminder_count
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      div(class: "mx-auto max-w-2xl px-6 py-10") do
        heading
        data_card
        danger_card
      end
    end
  end

  private

  def heading
    div(class: "mb-6") do
      h1(class: "mb-1 font-display text-2xl font-bold tracking-tight") { t(".title") }
      p(class: "text-text-secondary") { t(".subtitle") }
    end
  end

  def data_card
    render Components::Card.new(class: "mb-6 flex flex-col gap-4") do
      div(class: "flex items-center gap-4") do
        avatar
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

  def avatar
    if @user.avatar_url
      image_tag(@user.avatar_url, alt: "", loading: "lazy", class: "size-16 rounded-full object-cover")
    else
      span(class: "flex size-16 items-center justify-center rounded-full bg-accent-soft text-lg font-bold text-accent-soft-fg") do
        initials(@user.display_name)
      end
    end
  end
end
