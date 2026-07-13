# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::ScannableImages do
  let(:png_type) { "image/png" }
  let(:jpeg_type) { "image/jpeg" }

  describe ".attachments" do
    subject(:result) { described_class.attachments(message) }

    let(:message) { double("message", attachments:) }
    let(:image_att) { double("att", content_type: png_type, size: 1234, url: "https://cdn/a.png") }
    let(:attachments) { [image_att] }

    it "returns URLs of image attachments within size limit" do
      expect(result).to eq(["https://cdn/a.png"])
    end

    context "when attachment has non-image content type" do
      let(:attachments) { [double("att", content_type: "application/pdf", size: 1234, url: "https://cdn/x.pdf")] }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when attachment exceeds MAX_BYTES" do
      let(:attachments) { [double("att", content_type: png_type, size: 11 * 1024 * 1024, url: "https://cdn/big.png")] }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when there are more attachments than MAX" do
      let(:attachments) do
        Array.new(5) { |i| double("att#{i}", content_type: png_type, size: 1234, url: "https://cdn/#{i}.png") }
      end

      it "caps at MAX" do
        expect(result.length).to eq(4)
      end
    end

    context "when attachment is exactly at MAX_BYTES" do
      let(:attachments) { [double("att", content_type: jpeg_type, size: 10 * 1024 * 1024, url: "https://cdn/ok.jpg")] }

      it "includes it" do
        expect(result).to eq(["https://cdn/ok.jpg"])
      end
    end

    context "when attachment is a GIF" do
      let(:attachments) { [double("att", content_type: "image/gif", size: 1234, url: "https://cdn/anim.gif")] }

      it "includes it" do
        expect(result).to eq(["https://cdn/anim.gif"])
      end
    end
  end

  describe ".content_links" do
    subject(:result) { described_class.content_links(message) }

    let(:cdn_url) { "https://cdn.discordapp.com/attachments/123/456/scan.png?ex=abc&is=def&hm=xyz" }
    let(:message) { double("message", content: "check this out #{cdn_url}") }

    it "returns Discord CDN png link with signed query preserved" do
      expect(result).to eq([cdn_url])
    end

    context "when link is on media.discordapp.net" do
      let(:media_url) { "https://media.discordapp.net/attachments/1/2/img.jpg" }
      let(:message) { double("message", content: media_url) }

      it "returns it" do
        expect(result).to eq([media_url])
      end
    end

    context "when host looks like Discord CDN but has extra suffix (subdomain takeover attempt)" do
      let(:message) { double("message", content: "https://cdn.discordapp.com.evil.com/x.png") }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when host is a non-Discord domain" do
      let(:message) { double("message", content: "https://evil.com/x.png") }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when image extension is not in the allowlist" do
      let(:message) { double("message", content: "https://cdn.discordapp.com/a/file.pdf") }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when link uses http instead of https" do
      let(:message) { double("message", content: "http://cdn.discordapp.com/attachments/1/2/img.png") }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when content contains a malformed URL" do
      let(:message) { double("message", content: "https://cdn.discordapp.com/[bad") }

      it "skips it without raising" do
        expect(result).to be_empty
      end
    end

    context "when content is mixed text and a valid link" do
      let(:message) { double("message", content: "hey look at this #{cdn_url} pretty cool right") }

      it "extracts just the link" do
        expect(result).to eq([cdn_url])
      end
    end

    context "when there are more than MAX valid links" do
      let(:urls) do
        Array.new(5) { |i| "https://cdn.discordapp.com/attachments/#{i}/#{i}/img#{i}.png" }
      end
      let(:message) { double("message", content: urls.join(" ")) }

      it "caps at MAX" do
        expect(result.length).to eq(4)
      end
    end

    context "when the link is a GIF" do
      let(:message) { double("message", content: "https://cdn.discordapp.com/attachments/1/2/anim.gif") }

      it "returns it" do
        expect(result).to eq(["https://cdn.discordapp.com/attachments/1/2/anim.gif"])
      end
    end

    context "when the link uses a non-standard port" do
      let(:message) { double("message", content: "https://cdn.discordapp.com:8443/attachments/1/2/x.png") }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when a valid link ends a sentence with trailing punctuation" do
      let(:message) { double("message", content: "see #{cdn_url}.") }

      it "strips the punctuation and returns the link" do
        expect(result).to eq([cdn_url])
      end
    end

    context "when content is nil" do
      let(:message) { double("message", content: nil) }

      it "returns empty array" do
        expect(result).to eq([])
      end
    end

    context "when content is empty string" do
      let(:message) { double("message", content: "") }

      it "returns empty array" do
        expect(result).to eq([])
      end
    end
  end

  describe ".embeds" do
    subject(:result) { described_class.embeds(message) }

    let(:message) { double("message", embeds:) }
    let(:embed_image) { double("img", proxy_url: "https://media.discordapp.net/a.png", content_type: png_type) }
    let(:embed) { double("embed", image: embed_image) }
    let(:embeds) { [embed] }

    it "returns proxy_url of embed images with allowed content type" do
      expect(result).to eq(["https://media.discordapp.net/a.png"])
    end

    context "when embed has no image" do
      let(:embeds) { [double("embed", image: nil)] }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when embed image has nil proxy_url" do
      let(:embed_image) { double("img", proxy_url: nil, content_type: png_type) }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when embed image has non-whitelisted content type" do
      let(:embed_image) { double("img", proxy_url: "https://media.discordapp.net/x.bmp", content_type: "image/bmp") }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when embed image is a GIF" do
      let(:embed_image) { double("img", proxy_url: "https://media.discordapp.net/a.gif", content_type: "image/gif") }

      it "returns it" do
        expect(result).to eq(["https://media.discordapp.net/a.gif"])
      end
    end

    context "when embed image has nil content type" do
      let(:embed_image) { double("img", proxy_url: "https://media.discordapp.net/x", content_type: nil) }

      it "skips it" do
        expect(result).to be_empty
      end
    end

    context "when there are more embed images than MAX" do
      let(:embeds) do
        Array.new(5) do |i|
          img = double("img#{i}", proxy_url: "https://media.discordapp.net/#{i}.png", content_type: png_type)
          double("embed#{i}", image: img)
        end
      end

      it "caps at MAX" do
        expect(result.length).to eq(4)
      end
    end
  end

  describe ".all" do
    subject(:result) { described_class.all(message) }

    let(:message) do
      double(
        "message",
        attachments: [double("att", content_type: png_type, size: 1234, url: "https://cdn/a.png")],
        content: "https://cdn.discordapp.com/attachments/1/2/link.png",
        embeds: [double("embed", image: double("img", proxy_url: "https://media.discordapp.net/e.png", content_type: png_type))]
      )
    end

    it "unions attachments, content links, and embed images" do
      expect(result).to contain_exactly(
        "https://cdn/a.png",
        "https://cdn.discordapp.com/attachments/1/2/link.png",
        "https://media.discordapp.net/e.png"
      )
    end

    context "when the message is nil" do
      let(:message) { nil }

      it "returns an empty array" do
        expect(result).to eq([])
      end
    end

    context "when the same URL appears in more than one source" do
      let(:dup_url) { "https://cdn.discordapp.com/attachments/1/2/dup.png" }
      let(:message) do
        double(
          "message",
          attachments: [double("att", content_type: png_type, size: 1234, url: dup_url)],
          content: dup_url,
          embeds: []
        )
      end

      it "deduplicates across sources" do
        expect(result).to eq([dup_url])
      end
    end
  end
end
