# frozen_string_literal: true

module Ops
  module Integrations
    module Twitch
      module Watches
        class Discover < ApplicationOperation
          self.transactional = false

          receives :streams

          def call
            ids = streams.map(&:user_id).uniq
            missing = ids - existing(ids).keys
            create(missing) if missing.any?
            ok(existing(ids))
          end

          private

          def existing(ids)
            ::Integrations::Watch.where(watcher: watcher_name, external_id: ids).index_by(&:external_id)
          end

          def create(ids)
            rows = ::Integrations::Twitch::Users.new.for(ids).map do |user|
              {
                watcher: watcher_name,
                external_id: user.id,
                name: user.display_name,
                image_url: user.profile_image_url,
                url: ::Integrations::Twitch::ChannelReference.url(user.login)
              }
            end
            return if rows.empty?

            ::Integrations::Watch.insert_all(rows, unique_by: :index_integration_watches_on_watcher_and_external_id)
          end

          def watcher_name
            ::Integrations::Twitch::ChannelWatcher.name
          end
        end
      end
    end
  end
end
