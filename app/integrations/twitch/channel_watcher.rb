# frozen_string_literal: true

module Integrations
  module Twitch
    class ChannelWatcher
      def self.resolve(input, users: Users.new)
        target(users.find_by_login(ChannelReference.parse(input)))
      end

      def self.refresh(external_ids, users: Users.new)
        users.for(external_ids).map { |user| target(user) }
      end

      def self.followed_for_live
        Watch.demanding([StreamStarted.name]).where(watcher: name)
      end

      def self.live_checked
        followed_for_live.or(Watch.where(watcher: name).where("state ? 'session'"))
      end

      def self.target(user)
        Target.new(external_id: user.id, name: user.display_name, image_url: user.profile_image_url)
      end
      private_class_method :target
    end
  end
end
