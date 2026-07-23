# frozen_string_literal: true

module Bot
  module Discord
    module Components
      CONTAINER = 17
      TEXT_DISPLAY = 10
      SEPARATOR = 14
      MEDIA_GALLERY = 12
      SECTION = 9
      THUMBNAIL = 11
      ACTION_ROW = 1
      BUTTON = 2
      BUTTON_PRIMARY = 1
      BUTTON_SECONDARY = 2
      BUTTON_SUCCESS = 3
      BUTTON_DANGER = 4
      BUTTON_LINK = 5
      COMPONENTS_V2 = 1 << 15

      module_function

      def action_row(components)
        {type: ACTION_ROW, components:}
      end

      def button(custom_id:, label:, style: BUTTON_PRIMARY)
        {type: BUTTON, style:, label:, custom_id:}
      end

      def link_button(url:, label:)
        {type: BUTTON, style: BUTTON_LINK, url:, label:}
      end

      def container(blocks, accent_color: Config::ACCENT_COLOR, buttons: [])
        components = [{type: CONTAINER, accent_color:, components: blocks}]
        components << action_row(buttons) if buttons.any?
        {components:, flags: COMPONENTS_V2}
      end

      def text(body)
        {type: TEXT_DISPLAY, content: body}
      end

      def separator
        {type: SEPARATOR, divider: true}
      end

      def section(blocks, accessory:)
        {type: SECTION, components: blocks, accessory:}
      end

      def thumbnail(url)
        {type: THUMBNAIL, media: {url:}}
      end

      def media_gallery(urls)
        {type: MEDIA_GALLERY, items: urls.map { |url| {media: {url:}} }}
      end

      def create_message(channel_id:, content:, allowed_mentions:, reply_to_id: nil)
        response = Discordrb::API::Channel.create_message(
          Bot::Config.rest_token,
          channel_id,
          content,
          false,
          nil,
          nil,
          nil,
          allowed_mentions,
          reply_to_id && {message_id: reply_to_id},
          nil,
          nil
        )
        JSON.parse(response)["id"]
      end

      def send_to(channel, rendered, allowed_mentions: nil, attachments: nil, subject: nil)
        unless subject
          return channel.send_message(nil, false, nil, attachments, allowed_mentions, nil, rendered[:components], rendered[:flags])
        end

        message = channel.send_message(subject, false, nil, attachments, allowed_mentions, nil, nil, 0)
        convert_to_v2(channel.id, message.id, rendered)
        message
      end

      def convert_to_v2(channel_id, message_id, rendered)
        Discordrb::API::Channel.edit_message(
          Bot::Config.rest_token,
          channel_id,
          message_id,
          nil,
          {parse: []},
          nil,
          rendered[:components],
          rendered[:flags]
        )
      rescue => e
        Rails.logger.warn("[Components] message #{message_id} left as plain text: #{e.class}: #{e.message}")
      end
    end
  end
end
