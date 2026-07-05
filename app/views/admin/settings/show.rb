# frozen_string_literal: true

class Views::Admin::Settings::Show < Views::Base
  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      div(class: "mx-auto max-w-2xl px-6 py-10") do
        heading
        render Components::Admin::OwnerDmCard.new
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
end
