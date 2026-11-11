# frozen_string_literal: true

module Ops
  module Feeds
    module Posts
      class Revise < ApplicationOperation
        self.transactional = false

        receives :post, :event

        def call
          return ok unless latest?
          return revive if revivable?
          return ok unless post.message_id

          source.retract?(subscription, event) ? retract : edit
          ok
        rescue Discordrb::Errors::UnknownMessage, Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
          post.update!(message_id: nil, retracted_at: nil)
          ok
        end

        private

        def latest?
          ::Integrations::Event
            .in_story(event.watch_id, post.story_key)
            .order(occurred_at: :desc, created_at: :desc, id: :desc)
            .pick(:id) == event.id
        end

        def subscription
          post.subscription
        end

        def source
          subscription.source
        end

        def retract
          ::Bot::Discord::Components.delete_message(post.channel_id, post.message_id)
          post.update!(message_id: nil, retracted_at: Time.current)
        end

        def edit
          ::Bot::Discord::Components.edit(channel_id: post.channel_id, message_id: post.message_id, rendered: announcement.card)
        end

        def revivable?
          post.message_id.nil? &&
            post.retracted_at.present? &&
            source.revive?(subscription, event) &&
            ::Feeds::StoryPick.new(subscription:, event:).eligible?
        end

        def revive
          channel_id = subscription.channel_for(event.type)
          message_id = ::Feeds::AnnouncementMessage.create(
            channel_id:,
            announcement:,
            allowed_mentions: {parse: []}
          )
          post.update!(channel_id:, message_id:, retracted_at: nil)
          ok
        end

        def announcement
          source.announcement(event:, subscription:)
        end
      end
    end
  end
end
