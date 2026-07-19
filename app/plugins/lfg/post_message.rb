# frozen_string_literal: true

module Lfg
  module PostMessage
    MACHINE = /\[lfg\] r:(\d+) c:(\d+) s:(\d+) n:(\d+|-) m:(\S+) j:([\d,]*)/

    module_function

    def render(role_id:, creator_id:, start_ts:, message:, joiner_ids:, notify_reply_id:, started:)
      blocks = [
        Bot::Discord::Components.text(heading(role_id:, creator_id:, start_ts:, message:, started:)),
        Bot::Discord::Components.text(joiners_block(joiner_ids)),
        Bot::Discord::Components.text(machine_line(role_id:, creator_id:, start_ts:, notify_reply_id:, message:, joiner_ids:))
      ]
      Bot::Discord::Components.container(blocks, buttons: buttons(creator_id, start_ts))
    end

    def parse(message_json)
      line = find_machine_line(message_json["components"])
      return nil unless line

      match = line.match(MACHINE)
      {
        role_id: match[1].to_i,
        creator_id: match[2].to_i,
        start_ts: match[3].to_i,
        notify_reply_id: ((match[4] == "-") ? nil : match[4].to_i),
        message: ((match[5] == "-") ? nil : Base64.urlsafe_decode64(match[5])),
        joiner_ids: match[6].split(",").reject(&:empty?).map(&:to_i)
      }
    end

    def heading(role_id:, creator_id:, start_ts:, message:, started:)
      note = message.present? ? " — “#{message}”" : ""
      if started
        "🎮 **<@&#{role_id}>** — <@#{creator_id}>'s game is on now!#{note}\nJump in and you'll be pinged."
      else
        "🎮 **<@&#{role_id}>** — <@#{creator_id}> is looking to play.#{note}\nStarting <t:#{start_ts}:R>. Hit **Join** to get pinged at start."
      end
    end

    def joiners_block(joiner_ids)
      return "*No one's in yet.*" if joiner_ids.empty?

      "**In (#{joiner_ids.size}):** " + joiner_ids.map { |id| "<@#{id}>" }.join(" ")
    end

    def machine_line(role_id:, creator_id:, start_ts:, notify_reply_id:, message:, joiner_ids:)
      encoded = message.present? ? Base64.urlsafe_encode64(message, padding: false) : "-"
      notify = notify_reply_id || "-"
      "-# [lfg] r:#{role_id} c:#{creator_id} s:#{start_ts} n:#{notify} m:#{encoded} j:#{joiner_ids.join(",")}"
    end

    def buttons(creator_id, start_ts)
      [
        Bot::Discord::Components.button(custom_id: CustomId.join(creator_id, start_ts), label: "Join", style: Bot::Discord::Components::BUTTON_SUCCESS),
        Bot::Discord::Components.button(custom_id: CustomId.done(creator_id, start_ts), label: "Done looking", style: Bot::Discord::Components::BUTTON_SECONDARY)
      ]
    end

    def find_machine_line(nodes)
      Array(nodes).each do |node|
        content = node["content"]
        return content if content.is_a?(String) && content.match?(MACHINE)

        nested = find_machine_line(node["components"])
        return nested if nested
      end
      nil
    end

    private_class_method :heading, :joiners_block, :machine_line, :buttons, :find_machine_line
  end
end
