# frozen_string_literal: true

class Views::Admin::Settings::Show < Views::Base
  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      div(class: "mx-auto max-w-2xl px-6 py-10") do
        render Components::PageHeading.new(title: t(".title"), subtitle: t(".subtitle"))
        render Components::Admin::OwnerDmCard.new
      end
    end
  end
end
