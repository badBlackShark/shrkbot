# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ReportScam do
  subject(:execute) { described_class.new(event).execute }

  let(:guild_id) { 111 }
  let!(:config) { create(:server_configuration, discord_id: guild_id) }

  let(:image_attachment) { double("att", content_type: "image/png", url: "https://cdn/x.png") }
  let(:attachments) { [image_attachment] }
  let(:target) { double("message", attachments:) }
  let(:server) { double("server", id: guild_id) }
  let(:event) do
    double(
      "event",
      target:,
      server:,
      defer: nil,
      edit_response: nil,
      respond: nil
    )
  end

  let(:client) { double("client") }

  before do
    allow(Moderation::Ocr::Client).to receive(:new).and_return(client)
    allow(client).to receive(:phash).and_return("deadbeefdeadbeef")
    allow(Moderation::ImageDownload).to receive(:call).and_return("bytes")
    allow(Ops::Moderation::Phashes::Confirm).to receive(:call)
  end

  context "when there is no target message" do
    let(:target) { nil }

    it "responds with the none message and never defers" do
      execute

      expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
      expect(event).not_to have_received(:defer)
      expect(Ops::Moderation::Phashes::Confirm).not_to have_received(:call)
    end
  end

  context "when the message has no image attachments" do
    let(:attachments) { [] }

    it "responds with the none message and never defers" do
      execute

      expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
      expect(event).not_to have_received(:defer)
      expect(Ops::Moderation::Phashes::Confirm).not_to have_received(:call)
    end
  end

  context "when the message has image attachments" do
    let(:other_image) { double("att2", content_type: "image/jpeg", url: "https://cdn/y.jpg") }
    let(:attachments) { [image_attachment, other_image] }

    it "defers, confirms each image, and edits the response with the count" do
      execute

      expect(event).to have_received(:defer).with(ephemeral: true)
      expect(Ops::Moderation::Phashes::Confirm).to have_received(:call).with(server_configuration: config, phash_hex: "deadbeefdeadbeef").twice
      expect(event).to have_received(:edit_response).with(content: a_string_including("2"))
    end
  end

  context "when a non-image attachment is mixed in" do
    let(:pdf) { double("pdf", content_type: "application/pdf", url: "https://cdn/x.pdf") }
    let(:attachments) { [image_attachment, pdf] }

    it "skips the non-image and confirms only the image" do
      execute
      expect(Ops::Moderation::Phashes::Confirm).to have_received(:call).once
    end
  end

  context "when one attachment fails to phash" do
    let(:bad_image) { double("bad", content_type: "image/png", url: "https://cdn/bad.png") }
    let(:attachments) { [image_attachment, bad_image] }

    before do
      allow(Moderation::ImageDownload).to receive(:call).with("https://cdn/bad.png").and_raise(Moderation::Ocr::Error, "boom")
    end

    it "counts only the successful confirmation without raising" do
      expect { execute }.not_to raise_error

      expect(Ops::Moderation::Phashes::Confirm).to have_received(:call).once
      expect(event).to have_received(:edit_response).with(content: a_string_including("1"))
    end
  end
end
