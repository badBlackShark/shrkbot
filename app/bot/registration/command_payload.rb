# frozen_string_literal: true

module Bot
  class CommandPayload
    def initialize(registration)
      @registration = registration
    end

    def to_h
      payload = {
        name: @registration.name,
        description: @registration.description,
        type: Discordrb::ApplicationCommand::TYPES[@registration.type] || @registration.type
      }

      if @registration.permissions.present?
        payload[:default_member_permissions] = Discordrb::Permissions.bits(@registration.permissions).to_s
      end

      if @registration.options_block
        builder = Discordrb::Interactions::OptionBuilder.new
        @registration.options_block.call(builder)
        payload[:options] = builder.to_a
      end

      if @registration.global?
        payload[:contexts] = @registration.contexts.map { |ctx| Discordrb::Interaction::CONTEXTS[ctx] }
      end

      payload
    end
  end
end
