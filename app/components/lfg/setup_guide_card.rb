# frozen_string_literal: true

class Components::Lfg::SetupGuideCard < Components::Base
  def view_template
    render Components::Card.new do
      heading
      p(class: "mt-1 text-sm text-text-secondary") { t(".intro") }
      div(class: "mt-4 flex flex-col gap-4") do
        item("at", t(".non_mentionable.title"), t(".non_mentionable.body"))
        item("sliders", t(".visibility.title"), t(".visibility.body"))
      end
    end
  end

  private

  def heading
    div(class: "flex items-center gap-2") do
      render Components::Icon.new("compass", class: "size-5 text-accent-soft-fg")
      h2(class: "text-sm font-semibold text-text-primary") { t(".title") }
    end
  end

  def item(icon, title, body)
    div(class: "flex gap-3 rounded-card bg-surface-sunken p-4") do
      render Components::Icon.new(icon, class: "mt-0.5 size-5 flex-none text-accent-soft-fg")
      div do
        p(class: "text-sm font-semibold text-text-primary") { title }
        p(class: "mt-1 text-sm text-text-secondary") { body }
      end
    end
  end
end
