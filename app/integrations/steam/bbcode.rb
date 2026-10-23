# frozen_string_literal: true

require "cgi"

module Integrations
  module Steam
    class Bbcode
      IMAGE_HOST = "https://clan.akamai.steamstatic.com/images"
      TAG = /\[(\/?)(\*|[a-z][a-z0-9]*)([= ][^\]]*)?\]/
      TAGS = {
        "p" => "p",
        "b" => "b",
        "i" => "i",
        "u" => "u",
        "s" => "s",
        "h1" => "h1",
        "h2" => "h2",
        "h3" => "h3",
        "h4" => "h4",
        "h5" => "h5",
        "strike" => "s",
        "list" => "ul",
        "olist" => "ol",
        "*" => "li",
        "quote" => "blockquote",
        "code" => "pre",
        "spoiler" => "spoiler",
        "table" => "table",
        "tr" => "tr",
        "th" => "th",
        "td" => "td",
        "expand" => "div"
      }.freeze

      def self.to_html(text)
        new(text).to_html
      end

      def initialize(text)
        @text = text.to_s
      end

      def to_html
        convert(rewrite_embeds(@text))
      end

      private

      def rewrite_embeds(text)
        text = text.gsub("{STEAM_CLAN_LOC_IMAGE}", IMAGE_HOST).gsub("{STEAM_CLAN_IMAGE}", IMAGE_HOST)
        text = text.gsub(/\[img\](.*?)\[\/img\]/m) { %([img src="#{$1.strip}"][/img]) }
        text = text.gsub(/\[url\](.*?)\[\/url\]/m) { %([url="#{$1.strip}"]#{$1.strip}[/url]) }
        text = text.gsub(/\[previewyoutube=([^;\]]+)[^\]]*\]\s*\[\/previewyoutube\]/) { link_paragraph("https://www.youtube.com/watch?v=#{$1}") }
        text = text.gsub(/\[video\s+([^\]]*)\]\s*\[\/video\]/) { video_link($1) }
        text.gsub(/\[dynamiclink\s+[^\]]*?href="([^"]*)"[^\]]*\]\s*\[\/dynamiclink\]/) { link_paragraph($1) }
      end

      def video_link(attributes)
        url = attributes[/mp4="([^"]*)"/, 1] || attributes[/webm="([^"]*)"/, 1]
        url ? link_paragraph(url) : ""
      end

      def link_paragraph(url)
        %([p][url="#{url}"]#{url}[/url][/p])
      end

      def convert(text)
        html = +""
        position = 0
        text.scan(TAG) do
          match = Regexp.last_match
          html << escape(text[position...match.begin(0)]) << tag(match)
          position = match.end(0)
        end
        html << escape(text[position..])
      end

      def escape(text)
        CGI.escapeHTML(text).gsub("\n", "<br>")
      end

      def tag(match)
        closing = match[1] == "/"
        name = match[2]
        return html_tag(TAGS[name], closing) if TAGS.key?(name)

        case name
        when "hr" then closing ? "" : "<hr>"
        when "url" then url_tag(match, closing)
        when "img" then closing ? "" : image_tag(match)
        else CGI.escapeHTML(match[0])
        end
      end

      def html_tag(name, closing)
        closing ? "</#{name}>" : "<#{name}>"
      end

      def url_tag(match, closing)
        return "</a>" if closing

        href = match[3].to_s.sub(/\A=/, "").strip.delete_prefix('"').delete_suffix('"')
        %(<a href="#{CGI.escapeHTML(href)}">)
      end

      def image_tag(match)
        src = match[3].to_s[/src="?([^"\s]*)/, 1]
        %(<img src="#{CGI.escapeHTML(src.to_s)}">)
      end
    end
  end
end
