# frozen_string_literal: true

module Integrations
  class HtmlToMarkdown
    Result = Data.define(:markdown, :image_urls)

    BLOCKS = %w[p div section article header footer figure h1 h2 h3 h4 h5 h6 ul ol blockquote pre table hr].freeze
    DROPPED = %w[script style template head].freeze
    MARKERS = {
      "b" => "**",
      "strong" => "**",
      "i" => "*",
      "em" => "*",
      "u" => "__",
      "s" => "~~",
      "strike" => "~~",
      "del" => "~~",
      "spoiler" => "||"
    }.freeze
    ZERO_WIDTH = "\u200B\u200C\uFEFF"
    WEB_URL = %r{\Ahttps?://}i

    def self.call(html)
      new(html).call
    end

    def initialize(html)
      @fragment = Nokogiri::HTML5.fragment(html.to_s)
      @image_urls = []
    end

    def call
      markdown = tidy(children(@fragment))
      Result.new(markdown:, image_urls: @image_urls.uniq)
    end

    private

    def tidy(text)
      text.gsub(/[ \t]+$/, "").gsub(/\n{3,}/, "\n\n").strip
    end

    def children(node)
      node.children.map { |child| render(child) }.join
    end

    def render(node)
      return node.text.gsub(/\s+/, " ") if node.text?
      return "" unless node.element?

      render_element(node)
    end

    def render_element(node)
      case node.name
      when *DROPPED then ""
      when /\Ah[1-6]\z/ then block(heading(node))
      when "ul", "ol" then block(list(node))
      when *MARKERS.keys then wrap(children(node), MARKERS.fetch(node.name))
      when "br" then "\n"
      when "a" then link(node)
      when "img" then lift_image(node)
      when "code" then wrap(plain_text(node).squish, "`")
      when "blockquote" then block(quote(node))
      when "pre" then block(fence(plain_text(node).chomp))
      when "table" then block(table(node))
      when *BLOCKS then block(children(node))
      else children(node)
      end
    end

    def plain_text(node)
      return "\n" if node.element? && node.name == "br"
      return node.text if node.text?

      node.children.map { |child| plain_text(child) }.join
    end

    def block(inner)
      "\n\n#{inner}\n\n"
    end

    def heading(node)
      text = children(node).strip.tr("\n", " ")
      level = node.name[1].to_i
      (level <= 3) ? "#{"#" * level} #{text}" : "**#{text}**"
    end

    def wrap(inner, marker)
      leading, content, trailing = inner.match(/\A(\s*)(.*?)(\s*)\z/m).captures
      return inner if content.empty?

      "#{leading}#{marker}#{content}#{marker}#{trailing}"
    end

    def link(node)
      href = node["href"].to_s
      return children(node) unless href.match?(WEB_URL)

      text = children(node).strip.tr("\n", " ")
      return "" if text.empty?

      (text == href) ? href : "[#{text}](#{href})"
    end

    def lift_image(node)
      src = node["src"].to_s
      @image_urls << src if src.match?(WEB_URL)
      ""
    end

    def list(node)
      items = node.element_children.select { |child| child.name == "li" }
      items.each_with_index.map { |item, index| list_item(item, marker(node, index)) }.join("\n")
    end

    def marker(list, index)
      (list.name == "ol") ? "#{index + 1}. " : "- "
    end

    def list_item(item, marker)
      content = children(item).strip.gsub(/\n\s*\n/, "\n")
      marker + content.gsub("\n", "\n#{" " * marker.size}")
    end

    def quote(node)
      tidy(children(node)).gsub(/\n{2,}/, "\n").gsub(/^/, "> ")
    end

    def fence(text)
      "```\n#{text}\n```"
    end

    def table(node)
      node.css("img").each { |image| lift_image(image) }
      rows = node.css("tr").map { |row| row.css("th, td").map { |cell| cell_text(cell) } }.reject(&:empty?)
      return "" if rows.empty?

      widths = column_widths(rows)
      fence(rows.map { |cells| table_line(cells, widths) }.join("\n"))
    end

    def cell_text(cell)
      plain_text(cell).delete(ZERO_WIDTH).gsub(/\s+/, " ").strip
    end

    def column_widths(rows)
      Array.new(rows.map(&:size).max) { |column| rows.filter_map { |cells| cells[column]&.size }.max }
    end

    def table_line(cells, widths)
      last = widths.size - 1
      cells.each_with_index.map { |cell, column| (column < last) ? cell.ljust(widths[column]) : cell }.join("  ").rstrip
    end
  end
end
