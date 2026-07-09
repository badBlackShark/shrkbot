# frozen_string_literal: true

module Discord
  module Components
    CONTAINER = 17
    TEXT_DISPLAY = 10
    SEPARATOR = 14
    MEDIA_GALLERY = 12
    ACTION_ROW = 1
    BUTTON = 2
    BUTTON_SUCCESS = 3
    BUTTON_DANGER = 4
    COMPONENTS_V2 = 1 << 15

    module_function

    def action_row(components)
      {type: ACTION_ROW, components:}
    end

    def button(custom_id:, label:, style: 1)
      {type: BUTTON, style:, label:, custom_id:}
    end

    def container(blocks, accent_color: BotConfig::ACCENT_COLOR)
      {components: [{type: CONTAINER, accent_color:, components: blocks}], flags: COMPONENTS_V2}
    end

    def text(body)
      {type: TEXT_DISPLAY, content: body}
    end

    def separator
      {type: SEPARATOR, divider: true}
    end

    def media_gallery(urls)
      {type: MEDIA_GALLERY, items: urls.map { |url| {media: {url:}} }}
    end

    def send_to(channel, rendered, allowed_mentions: nil, attachments: nil)
      channel.send_message(nil, false, nil, attachments, allowed_mentions, nil, rendered[:components], rendered[:flags])
    end
  end
end
