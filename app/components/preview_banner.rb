# frozen_string_literal: true

class Components::PreviewBanner < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def view_template
    div(class: "flex flex-none flex-wrap items-center gap-3 border-b border-accent-soft-bd bg-accent-soft px-5 py-2.5 text-sm text-accent-soft-fg") do
      render Components::Icon.new("eye", class: "size-[18px] flex-none")
      p(class: "flex-1 font-medium") { t(".message") }
      div(class: "flex flex-none items-center gap-2") do
        invite_button
        leave_button
      end
    end
  end

  private

  def invite_button
    render Components::Button.new(
      variant: :primary,
      size: :sm,
      href: Bot::Config.invite_url,
      icon: "plus",
      label: t(".invite")
    )
  end

  def leave_button
    button_to(
      preview_path,
      method: :delete,
      class: Components::Button.css(variant: :secondary, size: :sm)
    ) { t(".leave") }
  end
end
