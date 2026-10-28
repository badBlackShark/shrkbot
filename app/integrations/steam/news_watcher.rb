# frozen_string_literal: true

module Integrations
  module Steam
    class NewsWatcher
      VOLUME_SAMPLE = 20

      def self.resolve(input, apps: Apps.new)
        app = apps.find(AppReference.parse(input))
        Target.new(external_id: app.id.to_s, name: app.name, image_url: app.header_image_url)
      end

      def self.volume(external_id, news: News.new)
        items = news.for_app(external_id, count: VOLUME_SAMPLE, maxlength: 1)
        Volume.new(counts: items.map { |item| event_class(item).name }.tally, sample_size: items.size)
      end

      def self.event_class(item)
        return ArticlePublished if item.feed_type.zero?

        item.tags.include?("patchnotes") ? PatchNotesPublished : AnnouncementPublished
      end

      def initialize(watch, news: News.new)
        @watch = watch
        @news = news
      end

      def observe
        recent = @watch.events.to_a
        events = @news.for_app(@watch.external_id).map { |item| event(item) }
        Stories.new(recent).assign(events)
      end

      private

      def event(item)
        converted = HtmlToMarkdown.call(html(item))
        self.class.event_class(item).new(
          watch: @watch,
          subject_key: item.gid,
          occurred_at: item.published_at,
          title: item.title,
          url: item.url,
          author: item.author,
          feed_name: item.feed_name,
          feed_label: item.feed_label,
          body: converted.markdown,
          image_urls: converted.image_urls
        )
      end

      def html(item)
        (item.feed_type == 1) ? Bbcode.to_html(item.contents) : item.contents
      end
    end
  end
end
