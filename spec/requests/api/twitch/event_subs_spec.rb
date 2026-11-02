# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Twitch::EventSubs", type: :request do
  describe "POST /api/twitch/eventsub" do
    subject(:post_message) { post api_twitch_event_sub_path, params: body, headers: }

    let(:secret) { "test-secret-123" }
    let(:message_type) { "notification" }
    let(:timestamp) { Time.current.utc.iso8601 }
    let(:body) { payload.to_json }
    let(:signed_body) { body }
    let(:signature) { "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, "msg-1#{timestamp}#{signed_body}")}" }
    let(:event) { {"id" => "s1", "broadcaster_user_id" => "1"} }
    let(:payload) { {"subscription" => {"type" => "stream.online", "condition" => {"broadcaster_user_id" => "1"}, "status" => "enabled"}, "event" => event} }
    let(:headers) do
      {
        "CONTENT_TYPE" => "application/json",
        "Twitch-Eventsub-Message-Id" => "msg-1",
        "Twitch-Eventsub-Message-Timestamp" => timestamp,
        "Twitch-Eventsub-Message-Signature" => signature,
        "Twitch-Eventsub-Message-Type" => message_type
      }
    end

    before do
      stub_const("ENV", ENV.to_h.merge("TWITCH_EVENTSUB_SECRET" => secret))
    end

    context "with a callback verification" do
      let(:message_type) { "webhook_callback_verification" }
      let(:payload) { {"challenge" => "pogchamp-kappa-360", "subscription" => {"type" => "stream.online"}} }

      it "answers the challenge as plain text" do
        post_message

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/plain")
        expect(response.body).to eq("pogchamp-kappa-360")
      end
    end

    context "with a notification" do
      it "enqueues it and answers 204" do
        expect { post_message }.to have_enqueued_job(Integrations::Twitch::NotificationJob).with("stream.online", event)

        expect(response).to have_http_status(:no_content)
      end
    end

    context "with a revocation" do
      let(:message_type) { "revocation" }
      let(:payload) { {"subscription" => {"type" => "stream.online", "condition" => {"broadcaster_user_id" => "1"}, "status" => "authorization_revoked"}} }

      it "enqueues a reconcile and answers 204" do
        expect { post_message }.to have_enqueued_job(Integrations::Twitch::EventSubReconcileJob)

        expect(response).to have_http_status(:no_content)
      end
    end

    context "with a bad signature" do
      let(:signature) { "sha256=#{"0" * 64}" }

      it "answers 403 and enqueues nothing" do
        expect { post_message }.not_to have_enqueued_job

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with a stale timestamp" do
      let(:timestamp) { 11.minutes.ago.utc.iso8601 }

      it "answers 403 and enqueues nothing" do
        expect { post_message }.not_to have_enqueued_job

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without a configured secret" do
      before do
        stub_const("ENV", ENV.to_h.merge("TWITCH_EVENTSUB_SECRET" => ""))
      end

      it "answers 403" do
        post_message

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with a signed unknown message type" do
      let(:message_type) { "mystery" }

      it "answers 400" do
        post_message

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with a signed notification missing its subscription" do
      let(:body) { {event: {broadcaster_user_id: "1"}}.to_json }

      it "answers 400 and enqueues nothing" do
        expect { post_message }.not_to have_enqueued_job
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with a signed malformed body" do
      let(:body) { "{not json" }

      it "answers 400" do
        post_message

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
