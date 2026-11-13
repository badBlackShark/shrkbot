# frozen_string_literal: true

class Components::Lfg::ChannelsField < Components::Base
  def initialize(channels:, selected:)
    @channels = channels
    @selected = selected
  end

  def view_template
    div do
      render Components::FieldLabel.new { t(".label") }
      if @channels.empty?
        p(class: "text-sm text-text-secondary") { t(".none") }
      else
        render Components::ChannelSelect.new(
          name: "lfg[allowed_channel_ids][]",
          options: @channels,
          selected: @selected,
          placeholder: t(".placeholder"),
          multiple: true
        )
      end
      nudge_callout if @selected.blank?
    end
  end

  private

  def nudge_callout
    div(class: "mt-3") do
      render Components::Callout.new(variant: :info) { t(".nudge") }
    end
  end
end
