# frozen_string_literal: true

class Components::DiscordMessagePreview < Components::Base
  include Phlex::Rails::Helpers::ImageTag

  MESSAGE_TEXT_CLASSES = "whitespace-pre-wrap text-sm leading-relaxed text-[color:var(--discord-text)]"
  CARD_CLASSES = "mt-2 max-w-lg rounded-lg border border-[color:var(--discord-code-bd)] bg-[var(--discord-code-bg)] p-3 text-[color:var(--discord-text)]"
  IMAGE_PLACEHOLDER = "flex items-center justify-center rounded-lg bg-[var(--discord-divider)] p-2 text-center text-xs text-[color:var(--discord-muted)]"

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
        message_text(message[:body_data]) if message[:body_data]
        card_with_button(message[:card]) if message[:card]
      end
    end
  end

  def message_text(data)
    div(class: MESSAGE_TEXT_CLASSES, data:)
  end

  def card_header(card)
    div(class: "min-w-0") do
      p(class: "text-xs text-[color:var(--discord-muted)]") { card[:eyebrow] } if card[:eyebrow]
      p(class: "text-base font-bold") { card[:title] }
    end
  end

  def card(card)
    div(class: CARD_CLASSES) do
      card_section(card)
      card_media(card[:media]) if card[:media]
      div(class: "mt-3") { card_lines(card[:footer]) } if card[:footer]
    end
  end

  def card_section(card)
    div(class: "flex items-start gap-3") do
      div(class: "min-w-0 flex-1") do
        card_header(card)
        div(class: "mt-1") { card_lines(lines_of(card[:body])) }
      end
      image_placeholder(card[:thumbnail], "size-[85px] flex-none") if card[:thumbnail]
    end
  end

  def card_media(media)
    div(class: media[:class]) do
      image_placeholder(media[:label], "mt-3 aspect-video w-[32rem] max-w-full")
    end
  end

  def lines_of(body)
    body.is_a?(Array) ? body : [{text: body, class: nil}]
  end

  def card_lines(lines)
    lines.each do |line|
      p(class: ["whitespace-pre-wrap text-sm", line[:class]].compact.join(" ")) { line[:text] }
    end
  end

  def image_placeholder(label, shape)
    div(class: "#{IMAGE_PLACEHOLDER} #{shape}") { label }
  end

  def card_with_button(content)
    card(content)
    card_button(content[:button]) if content[:button]
  end

  def card_button(label)
    span(class: "mt-2 inline-flex items-center gap-1.5 rounded bg-[var(--discord-divider)] px-3 py-1.5 text-sm font-medium") do
      plain label
      render Components::Icon.new("arrow-square-out", class: "size-3.5")
    end
  end
end
