# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ReportScam do
  subject(:execute) { described_class.new(event).execute }

  let(:guild_id) { 111 }
  let!(:config) { create(:server_configuration, discord_id: guild_id) }

  let(:author_id) { 333 }
  let(:channel_id) { 444 }
  let(:image_attachment) { double("att", content_type: "image/png", url: "https://cdn/x.png") }
  let(:attachments) { [image_attachment] }
  let(:message_author) { double("author", id: author_id) }
  let(:target) { double("message", attachments:, author: message_author, delete: nil) }
  let(:server) { double("server", id: guild_id) }
  let(:user) { double("user", id: 555) }
  let(:channel) { double("channel", id: channel_id) }
  let(:bot) { double("bot") }
  let(:event) do
    double(
      "event",
      target:,
      server:,
      user:,
      channel:,
      bot:,
      defer: nil,
      edit_response: nil,
      respond: nil
    )
  end

  let(:image_scanning_settings) { double("image_scanning_settings", action: "none") }
  let(:client) { double("client") }

  before do
    allow(ServerConfiguration).to receive(:find_by).with(discord_id: guild_id).and_return(config)
    allow(config).to receive(:image_scanning_settings).and_return(image_scanning_settings)
    allow(ActivityLog).to receive(:post)
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

  context "when at least one image was confirmed and action is delete" do
    let(:image_scanning_settings) { double("image_scanning_settings", action: "delete") }

    it "deletes the reported message" do
      execute
      expect(target).to have_received(:delete)
    end

    it "posts a mod-log entry with the removed meta" do
      execute

      expect(ActivityLog).to have_received(:post) do |_config, kwargs|
        expect(kwargs[:title]).to eq(I18n.t("moderation.image_scanning.report.log.title"))
        expect(kwargs[:meta]).to eq(I18n.t("moderation.image_scanning.report.log.meta.removed"))
        body = kwargs[:body]
        expect(body).to include("<@#{user.id}>")
        expect(body).to include("<@#{author_id}>")
        expect(body).to include("<##{channel_id}>")
        expect(kwargs[:image]).to be_a(Discord::FileUpload)
      end
    end
  end

  context "when the delete fails" do
    let(:image_scanning_settings) { double("image_scanning_settings", action: "delete") }

    before do
      allow(target).to receive(:delete).and_raise(RuntimeError, "forbidden")
    end

    it "logs the kept meta without raising" do
      expect { execute }.not_to raise_error

      expect(ActivityLog).to have_received(:post) do |_config, kwargs|
        expect(kwargs[:meta]).to eq(I18n.t("moderation.image_scanning.report.log.meta.kept"))
      end
    end
  end

  context "when at least one image was confirmed and action is none" do
    let(:image_scanning_settings) { double("image_scanning_settings", action: "none") }

    it "does not delete the message" do
      execute
      expect(target).not_to have_received(:delete)
    end

    it "posts a mod-log entry with the kept meta" do
      execute

      expect(ActivityLog).to have_received(:post) do |_config, kwargs|
        expect(kwargs[:meta]).to eq(I18n.t("moderation.image_scanning.report.log.meta.kept"))
      end
    end
  end

  context "when zero images were confirmed (all fail to phash)" do
    before do
      allow(Moderation::ImageDownload).to receive(:call).and_raise(Moderation::Ocr::Error, "boom")
    end

    it "does not post a mod-log entry and does not delete" do
      execute

      expect(ActivityLog).not_to have_received(:post)
      expect(target).not_to have_received(:delete)
    end
  end
end
