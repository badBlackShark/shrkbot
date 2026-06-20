module Discord
  module Components
    CONTAINER = 17
    TEXT_DISPLAY = 10
    SEPARATOR = 14
    COMPONENTS_V2 = 1 << 15

    module_function

    def container(blocks, accent_color: BotConfig::ACCENT_COLOR)
      {components: [{type: CONTAINER, accent_color: accent_color, components: blocks}], flags: COMPONENTS_V2}
    end

    def text(body)
      {type: TEXT_DISPLAY, content: body}
    end

    def separator
      {type: SEPARATOR, divider: true}
    end
  end
end
