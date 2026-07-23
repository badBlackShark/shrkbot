# frozen_string_literal: true

module Lfg
  module PostMessage
    JOINER = /<@(\d+)>/

    module_function

    def render(role_id:, creator_id:, start_ts:, message:, joiner_ids:, started:)
      blocks = [text(heading(role_id:, creator_id:, start_ts:, started:))]
      blocks << text(message) if message.present?
      blocks << text(joiners_block(joiner_ids))
      Bot::Discord::Components.container(blocks, buttons: buttons(creator_id, start_ts, role_id))
    end

    def parse(message_json)
      contents = text_contents(message_json["components"])
      return nil if contents.size < 2

      {
        joiner_ids: contents.last.scan(JOINER).flatten.map(&:to_i),
        message: ((contents.size >= 3) ? contents[1] : nil)
      }
    end

    def heading(role_id:, creator_id:, start_ts:, started:)
      if started
        "<@&#{role_id}> - <@#{creator_id}> is looking for a game right now! Click **Join** to ping them and let them know you're interested."
      else
        "<@&#{role_id}> - <@#{creator_id}> is looking to play, starting <t:#{start_ts}:R>! Click **Join** to let them know you'll be joining and to get pinged when the activity starts."
      end
    end

    def joiners_block(joiner_ids)
      return "No one's in yet." if joiner_ids.empty?

      "**In (#{joiner_ids.size}):** " + Mentions.list(joiner_ids)
    end

    def buttons(creator_id, start_ts, role_id)
      [
        Bot::Discord::Components.button(custom_id: CustomId.join(creator_id, start_ts, role_id), label: "Join", style: Bot::Discord::Components::BUTTON_SUCCESS),
        Bot::Discord::Components.button(custom_id: CustomId.done(creator_id, start_ts, role_id), label: "Done looking", style: Bot::Discord::Components::BUTTON_SECONDARY)
      ]
    end

    def text(body)
      Bot::Discord::Components.text(body)
    end

    def text_contents(components)
      Array(components).flat_map do |node|
        nested = text_contents(node["components"])
        content = node["content"]
        content.is_a?(String) ? [content, *nested] : nested
      end
    end

    private_class_method :heading, :joiners_block, :buttons, :text, :text_contents
  end
end
