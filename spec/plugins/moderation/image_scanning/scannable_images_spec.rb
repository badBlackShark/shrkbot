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

      it "caps at 3" do
        expect(result.length).to eq(3)
      end
    end

    context "when attachment is exactly at MAX_BYTES" do
      let(:attachments) { [double("att", content_type: jpeg_type, size: 10 * 1024 * 1024, url: "https://cdn/ok.jpg")] }

      it "includes it" do
        expect(result).to eq(["https://cdn/ok.jpg"])
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
      let(:embed_image) { double("img", proxy_url: "https://media.discordapp.net/x.gif", content_type: "image/gif") }

      it "skips it" do
        expect(result).to be_empty
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

      it "caps at 3" do
        expect(result.length).to eq(3)
      end
    end
  end
end
