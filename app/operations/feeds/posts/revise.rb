# frozen_string_literal: true

module Ops
  module Feeds
    module Posts
      class Revise < ApplicationOperation
        include ForgetsMessage

        self.transactional = false

        receives :post, :event

        def call
          return ok unless latest?

          forgetting_a_lost_card(post) do
            next revive if revivable?
            next ok unless post.message_id
            next hand_off_or_settle if source.switched_away?(subscription, event)

            settle
            ok
          end
        end

        private

        def hand_off_or_settle
          ::Feeds::StoryLock.hold(subscription.server_configuration, post.story_key) do
            post.reload
            next unless post.message_id && latest?

            successor = ::Feeds::CardOwnership.successor(post:, event:)
            successor ? HandOff.call(post:, subscription: successor, event:) : settle
          end
          ok
        end

        def settle
          source.retract?(subscription, event) ? retract : edit
        end

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
