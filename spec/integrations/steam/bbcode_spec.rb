# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Steam::Bbcode do
  subject(:html) { described_class.to_html(text) }

  describe "simple tags" do
    let(:text) { "[p]a[/p][b]b[/b][i]c[/i][u]d[/u][s]e[/s][strike]f[/strike][h1]g[/h1][h2]h[/h2][h3]i[/h3][h4]j[/h4][h5]k[/h5]" }

    it "keeps their names, mapping strike to s" do
      expect(html).to eq("<p>a</p><b>b</b><i>c</i><u>d</u><s>e</s><s>f</s><h1>g</h1><h2>h</h2><h3>i</h3><h4>j</h4><h5>k</h5>")
    end
  end

  describe "lists" do
    let(:text) { "[list][*]a[*]b[/list][olist][*]c[/olist]" }

    it "maps list, olist and * to ul, ol and li" do
      expect(html).to eq("<ul><li>a<li>b</ul><ol><li>c</ol>")
    end
  end

  describe "structure tags" do
    let(:text) { "[quote=Someone]q[/quote][code]c[/code][spoiler]s[/spoiler][expand type=details]e[/expand]" }

    it "maps quote, code and expand, dropping their attributes" do
      expect(html).to eq("<blockquote>q</blockquote><pre>c</pre><spoiler>s</spoiler><div>e</div>")
    end
  end

  describe "tables" do
    let(:text) { "[table][tr][th]h[/th][td]d[/td][/tr][/table]" }

    it "keeps table, tr, th and td" do
      expect(html).to eq("<table><tr><th>h</th><td>d</td></tr></table>")
    end
  end

  describe "hr" do
    let(:text) { "a[hr][/hr]b" }

    it "emits one hr and nothing for the close" do
      expect(html).to eq("a<hr>b")
    end
  end

  describe "urls" do
    context "with a value" do
      let(:text) { '[url="https://example.com/?a=1&b=2"]site[/url] [url=https://example.com/x]bare[/url]' }

      it "accepts quoted and unquoted values and escapes the attribute" do
        expect(html).to eq('<a href="https://example.com/?a=1&amp;b=2">site</a> <a href="https://example.com/x">bare</a>')
      end
    end

    context "with the content as the target" do
      let(:text) { "[url]https://example.com/x[/url]" }

      it "uses the content as href and text" do
        expect(html).to eq('<a href="https://example.com/x">https://example.com/x</a>')
      end
    end
  end

  describe "images" do
    context "with the content as the source" do
      let(:text) { "[img]https://example.com/a.png[/img]" }

      it "becomes an img element" do
        expect(html).to eq('<img src="https://example.com/a.png">')
      end
    end

    context "with an src attribute" do
      let(:text) { '[img src="https://example.com/a.png"][/img]' }

      it "becomes an img element" do
        expect(html).to eq('<img src="https://example.com/a.png">')
      end
    end

    context "with a Steam placeholder" do
      let(:text) { "[img]{STEAM_CLAN_IMAGE}/1/a.png[/img][img]{STEAM_CLAN_LOC_IMAGE}/1/b.png[/img]" }

      it "expands both placeholders to the clan image host" do
        expect(html).to eq(
          '<img src="https://clan.akamai.steamstatic.com/images/1/a.png">' \
          '<img src="https://clan.akamai.steamstatic.com/images/1/b.png">'
        )
      end
    end
  end

  describe "embeds" do
    context "with previewyoutube" do
      let(:text) { "[previewyoutube=dQw4w9WgXcQ;full][/previewyoutube]" }

      it "becomes a link to the video" do
        expect(html).to eq(
          '<p><a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">https://www.youtube.com/watch?v=dQw4w9WgXcQ</a></p>'
        )
      end
    end

    context "with a video offering mp4 and webm" do
      let(:text) { '[video controls="true" webm="https://example.com/v.webm" mp4="https://example.com/v.mp4"][/video]' }

      it "links the mp4" do
        expect(html).to eq('<p><a href="https://example.com/v.mp4">https://example.com/v.mp4</a></p>')
      end
    end

    context "with a video offering only webm" do
      let(:text) { '[video webm="https://example.com/v.webm"][/video]' }

      it "links the webm" do
        expect(html).to eq('<p><a href="https://example.com/v.webm">https://example.com/v.webm</a></p>')
      end
    end

    context "with a video offering no source" do
      let(:text) { 'a[video poster="https://example.com/p.png"][/video]b' }

      it "drops it" do
        expect(html).to eq("ab")
      end
    end

    context "with dynamiclink" do
      let(:text) { '[dynamiclink href="https://store.steampowered.com/app/440" type="app"][/dynamiclink]' }

      it "becomes a link to the href" do
        expect(html).to eq(
          '<p><a href="https://store.steampowered.com/app/440">https://store.steampowered.com/app/440</a></p>'
        )
      end
    end
  end

  describe "text" do
    let(:text) { "a < b & \"c\"\nnext" }

    it "escapes HTML and turns newlines into br" do
      expect(html).to eq("a &lt; b &amp; &quot;c&quot;<br>next")
    end
  end

  describe "unknown and uppercase tags" do
    let(:text) { "[PC] [Corrupted] [xbox]" }

    it "stay literal text, with unknown lowercase tags escaped" do
      expect(html).to eq("[PC] [Corrupted] [xbox]")
    end
  end
end
