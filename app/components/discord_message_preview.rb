# frozen_string_literal: true

class Components::DiscordMessagePreview < Components::Base
  include Phlex::Rails::Helpers::ImageTag

  def initialize(label:, channel: nil, bot_name: "shrkbot", messages: [])
    @label = label
    @channel = channel
    @bot_name = bot_name
    @messages = messages
  end

  def view_template
    div(class: "overflow-hidden rounded-lg bg-[var(--discord-surface)] shadow-md") do
      header
      @messages.each_with_index do |message, index|
        div(class: "mx-4 h-px bg-[var(--discord-divider)]") if index.positive?
        message_row(message)
      end
    end
  end

  private

  def header
    div(class: "flex items-center gap-2 border-b border-[color:var(--discord-divider)] px-4 py-2.5") do
      span(class: "text-xs font-semibold text-[color:var(--discord-muted)]") { @label }
      span(class: "text-xs text-[color:var(--discord-muted)]") { "· #{@channel}" } if @channel
    end
  end

  def message_row(message)
    div(class: "flex items-start gap-3 p-4") do
      image_tag("shrkbot-mascot.png", alt: "", class: "size-10 flex-none rounded-full")
      div(class: "min-w-0") do
        div(class: "mb-1 flex items-center gap-2") do
          span(class: "text-sm font-semibold text-[color:var(--discord-text)]") { @bot_name }
          span(class: "rounded bg-accent-fill px-1.5 py-0.5 text-[10px] font-semibold text-white") { "APP" }
          span(class: "text-[11px] text-[color:var(--discord-muted)]") { message[:timestamp] } if message[:timestamp]
        end
        p(class: "text-sm leading-relaxed text-[color:var(--discord-text)]", data: message[:body_data] || {})
      end
    end
  end
end
