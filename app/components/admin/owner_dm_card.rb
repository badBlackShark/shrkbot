# frozen_string_literal: true

class Components::Admin::OwnerDmCard < Components::Base
  def view_template
    div(id: "owner-dm-card") do
      render Components::Card.new(class: "flex items-center gap-4") do
        div(class: "flex-1") do
          p(class: "text-sm font-semibold") { t(".label") }
          p(class: "mt-0.5 text-sm text-text-secondary") { t(".description") }
        end
        render Components::Toggle.new(
          name: :owner_error_dms,
          checked: BotSetting.owner_error_dms?,
          label: t(".label"),
          url: admin_settings_path,
          submit_on_change: true
        )
      end
    end
  end
end
