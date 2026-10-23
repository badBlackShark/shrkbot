# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::HtmlToMarkdown do
  subject(:result) { described_class.call(html) }

  let(:markdown) { result.markdown }

  describe "text" do
    let(:html) { "<p>one \n\t  two</p>" }

    it "collapses whitespace runs to one space" do
      expect(markdown).to eq("one two")
    end
  end

  describe "br" do
    let(:html) { "a<br>b" }

    it "becomes a newline" do
      expect(markdown).to eq("a\nb")
    end
  end

  describe "block elements" do
    let(:html) { "<p>one</p><div>two</div>" }

    it "are separated by a blank line" do
      expect(markdown).to eq("one\n\ntwo")
    end
  end

  describe "headings" do
    let(:html) { "<h1>One</h1><h2>Two</h2><h3>Three</h3><h4>Four</h4>" }

    it "maps h1-h3 to Markdown headings and h4-h6 to bold" do
      expect(markdown).to eq("# One\n\n## Two\n\n### Three\n\n**Four**")
    end
  end

  describe "inline formatting" do
    let(:html) { "<b>a</b> <strong>b</strong> <i>c</i> <em>d</em> <u>e</u> <s>f</s> <strike>g</strike> <del>h</del> <spoiler>i</spoiler>" }

    it "maps every tag to its Discord marker" do
      expect(markdown).to eq("**a** **b** *c* *d* __e__ ~~f~~ ~~g~~ ~~h~~ ||i||")
    end

    context "with whitespace inside the tag" do
      let(:html) { "x<b> y </b>z" }

      it "keeps the whitespace outside the markers" do
        expect(markdown).to eq("x **y** z")
      end
    end

    context "with whitespace-only content" do
      let(:html) { "x<b> </b>y" }

      it "emits no markers" do
        expect(markdown).to eq("x y")
      end
    end
  end

  describe "links" do
    context "with differing text" do
      let(:html) { '<a href="https://example.com/x">site</a>' }

      it "renders a Markdown link" do
        expect(markdown).to eq("[site](https://example.com/x)")
      end
    end

    context "when the text equals the href" do
      let(:html) { '<a href="https://example.com/x">https://example.com/x</a>' }

      it "renders the bare URL" do
        expect(markdown).to eq("https://example.com/x")
      end
    end

    context "with a non-http href" do
      let(:html) { '<a href="javascript:alert(1)">click</a>' }

      it "keeps only the text" do
        expect(markdown).to eq("click")
      end
    end

    context "with empty text" do
      let(:html) { 'a<a href="https://example.com/x"> </a>b' }

      it "drops the link" do
        expect(markdown).to eq("ab")
      end
    end

    context "with multi-line text" do
      let(:html) { '<a href="https://example.com/x">two<br>lines</a>' }

      it "turns newlines in the text into spaces" do
        expect(markdown).to eq("[two lines](https://example.com/x)")
      end
    end
  end

  describe "images" do
    let(:html) do
      '<p>a</p><img src="https://example.com/1.png"><a href="https://example.com/x"><img src="https://example.com/2.png"></a>' \
        '<img src="https://example.com/1.png"><img src="data:image/png;base64,AAAA">'
    end

    it "lifts http(s) sources into image_urls, deduped and in order, and emits no text" do
      expect(result).to have_attributes(markdown: "a", image_urls: %w[https://example.com/1.png https://example.com/2.png])
    end
  end

  describe "lists" do
    context "when unordered and nested" do
      let(:html) { "<ul><li>Updated map<ul><br><li>Fixed skybox<br><li>Fixed art</ul><br><li>Next</ul>" }

      it "indents nested items by the marker width" do
        expect(markdown).to eq("- Updated map\n  - Fixed skybox\n  - Fixed art\n- Next")
      end
    end

    context "when ordered" do
      let(:html) { "<ol><li>a</li><li>b<ol><li>c</li></ol></li></ol>" }

      it "numbers items and indents continuation lines by the wider marker" do
        expect(markdown).to eq("1. a\n2. b\n   1. c")
      end
    end

    context "with stray children" do
      let(:html) { "<ul>stray<br><li>kept</li></ul>" }

      it "renders only the li children" do
        expect(markdown).to eq("- kept")
      end
    end

    context "with paragraphs inside an item" do
      let(:html) { "<ul><li><p>one</p><p>two</p></li></ul>" }

      it "squeezes blank lines to a single newline" do
        expect(markdown).to eq("- one\n  two")
      end
    end
  end

  describe "blockquote" do
    let(:html) { "<blockquote>one<br>two</blockquote>" }

    it "prefixes every line" do
      expect(markdown).to eq("> one\n> two")
    end

    context "when it holds paragraphs" do
      let(:html) { "<blockquote><p>one</p><p>two</p></blockquote>" }

      it "quotes them without a blank line between" do
        expect(markdown).to eq("> one\n> two")
      end
    end
  end

  describe "code" do
    context "when inline" do
      let(:html) { "run <code>bin/rails  s</code> now" }

      it "wraps the text in backticks" do
        expect(markdown).to eq("run `bin/rails s` now")
      end
    end

    context "when inline with a line break" do
      let(:html) { "<code>a<br>b</code>" }

      it "keeps the words apart" do
        expect(markdown).to eq("`a b`")
      end
    end

    context "when inside pre" do
      let(:html) { "<pre>a  b\n  c</pre>" }

      it "fences the raw text" do
        expect(markdown).to eq("```\na  b\n  c\n```")
      end
    end

    context "when inside pre with line breaks" do
      let(:html) { "<pre>a<br>b<br>  c</pre>" }

      it "keeps each break as a newline" do
        expect(markdown).to eq("```\na\nb\n  c\n```")
      end
    end
  end

  describe "tables" do
    let(:html) do
      "<table><tr><th>Position</th><th>Royalty</th></tr>" \
        "<tr><td>Tournament Organizer</td><td>5.0%</td></tr><tr><td>1</td><td>2.85%</td></tr></table>"
    end

    it "becomes a code block with padded columns" do
      expect(markdown).to eq("```\nPosition              Royalty\nTournament Organizer  5.0%\n1                     2.85%\n```")
    end

    context "with zero-width characters and an image in a cell" do
      let(:html) { "<table><tr><td>a\u200B</td><td><img src=\"https://example.com/t.png\">b</td></tr></table>" }

      it "strips the characters and lifts the image" do
        expect(result).to have_attributes(markdown: "```\na  b\n```", image_urls: ["https://example.com/t.png"])
      end
    end

    context "with a line break inside a cell" do
      let(:html) { "<table><tr><td>first<br>second</td></tr></table>" }

      it "turns the break into a space" do
        expect(markdown).to eq("```\nfirst second\n```")
      end
    end

    context "with rows of different lengths" do
      let(:html) { "<table><tr><td>a</td><td>b</td></tr><tr><td>ccc</td></tr></table>" }

      it "pads each column to its widest cell" do
        expect(markdown).to eq("```\na    b\nccc\n```")
      end
    end

    context "without any cells" do
      let(:html) { "a<table><tr></tr></table>b" }

      it "renders nothing" do
        expect(markdown).to eq("a\n\nb")
      end
    end
  end

  describe "comments" do
    let(:html) { "a<!-- hidden -->b" }

    it "are dropped" do
      expect(markdown).to eq("ab")
    end
  end

  describe "hr" do
    let(:html) { "a<hr>b" }

    it "only breaks the block" do
      expect(markdown).to eq("a\n\nb")
    end
  end

  describe "dropped elements" do
    let(:html) { "a<script>alert(1)</script><style>p{}</style><template>x</template>b" }

    it "are removed with their content" do
      expect(markdown).to eq("ab")
    end
  end

  describe "unknown elements" do
    let(:html) { "<custom>kept <span>text</span></custom>" }

    it "render their children" do
      expect(markdown).to eq("kept text")
    end
  end

  describe "tidying" do
    let(:html) { "<p>a   </p><p></p><p></p><p>b</p>" }

    it "strips trailing whitespace and collapses 3+ newlines to 2" do
      expect(markdown).to eq("a\n\nb")
    end
  end

  describe "the TF2 steam_updates fixture" do
    let(:html) do
      items = JSON.parse(Rails.root.join("spec/fixtures/integrations/steam/news_440.json").read).dig("appnews", "newsitems")
      items.find { |item| item["feedname"] == "steam_updates" }["contents"]
    end

    it "keeps the nested list structure" do
      expect(markdown).to include("- Updated cp_holyhell\n  - Fixed BLU side skybox not rendering for users with HDR enabled")
    end
  end
end
