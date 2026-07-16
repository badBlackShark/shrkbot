# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::AttachmentDownload do
  subject(:download) { described_class.call("https://cdn/x.png") }

  let(:http) { double("http") }
  let(:chunks) { ["by", "tes"] }
  let(:content_length) { nil }
  let(:response) { double("response", code: "200", content_length:) }

  before do
    allow(Net::HTTP).to receive(:start) { |*_args, &block| block.call(http) }
    allow(http).to receive(:request_get) { |_uri, &block| block.call(response) }
    allow(response).to receive(:read_body) { |&block| chunks.each { |chunk| block.call(chunk) } }
  end

  context "when the download succeeds" do
    it "returns the streamed body" do
      expect(download).to eq("bytes")
    end
  end

  context "when the download returns a non-success status" do
    let(:response) { double("response", code: "404", content_length: nil) }

    it "raises an AttachmentDownload::Error" do
      expect { download }.to raise_error(Moderation::AttachmentDownload::Error, /404/)
    end
  end

  context "when the connection fails" do
    before do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError, "no dns")
    end

    it "raises an AttachmentDownload::Error" do
      expect { download }.to raise_error(Moderation::AttachmentDownload::Error, "no dns")
    end
  end

  context "when the declared content length exceeds the cap" do
    let(:content_length) { described_class::MAX_BYTES + 1 }

    it "refuses without reading the body" do
      expect(response).not_to receive(:read_body)
      expect { download }.to raise_error(Moderation::AttachmentDownload::Error, /too large/)
    end
  end

  context "when the streamed body exceeds the cap" do
    subject(:download) { described_class.call("https://cdn/x.png", max_bytes: 3) }

    let(:chunks) { ["ab", "cd"] }

    it "raises once the byte budget is blown" do
      expect { download }.to raise_error(Moderation::AttachmentDownload::Error, /too large/)
    end
  end
end
