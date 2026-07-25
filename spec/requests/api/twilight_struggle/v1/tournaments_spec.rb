# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::TwilightStruggle::V1::Tournaments", type: :request do
  include_context "twilight struggle api auth"

  let(:external_id) { "tst-ext-new" }
  let(:params) { {tournament: {name: "Ameritash 2026"}} }

  describe "PUT /api/twilight-struggle/v1/tournaments/:external_id" do
    subject(:put_tournament) do
      put api_twilight_struggle_v1_tournament_path(external_id), params:, headers:, as: :json
    end

    context "without an Authorization header" do
      let(:headers) { {} }

      it "returns 401" do
        put_tournament

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a wrong token" do
      let(:headers) { {"Authorization" => "Bearer wrong-token"} }

      it "returns 401" do
        put_tournament

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with no Authorization header and an invalid body" do
      let(:headers) { {} }
      let(:params) { {tournament: {}} }

      it "fails closed on auth before validating the schema" do
        put_tournament

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an empty bearer token" do
      let(:headers) { {"Authorization" => "Bearer "} }

      it "returns 401 rather than erroring" do
        put_tournament

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with the second configured key" do
      let(:headers) { {"Authorization" => "Bearer key-two"} }

      it "authenticates" do
        put_tournament

        expect(response).to have_http_status(:created)
      end
    end

    context "when TWILIGHT_STRUGGLE_API_KEYS is blank" do
      before do
        allow(ENV).to receive(:fetch).with("TWILIGHT_STRUGGLE_API_KEYS", "").and_return("")
      end

      it "rejects even a plausible token" do
        put_tournament

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a new external_id" do
      it "returns 201" do
        put_tournament

        expect(response).to have_http_status(:created)
      end

      it "creates a row" do
        expect { put_tournament }.to change(TwilightStruggle::Tournament, :count).by(1)
      end

      it "returns the id and external_id in the body" do
        put_tournament

        body = response.parsed_body
        expect(body["external_id"]).to eq(external_id)
        expect(body["id"]).to be_present
      end
    end

    context "with an external_id that already exists" do
      let!(:tournament) { create(:twilight_struggle_tournament, external_id:, name: "Old Name") }

      it "returns 200" do
        put_tournament

        expect(response).to have_http_status(:ok)
      end

      it "updates in place instead of creating a new row" do
        expect { put_tournament }.not_to change(TwilightStruggle::Tournament, :count)
      end

      it "changes the updated field" do
        expect { put_tournament }.to change { tournament.reload.name }.from("Old Name").to("Ameritash 2026")
      end
    end

    context "with a parent_external_id referencing an existing tournament" do
      let!(:parent) { create(:twilight_struggle_tournament) }
      let(:params) { {tournament: {name: "Child", parent_external_id: parent.external_id}} }

      it "links the parent" do
        put_tournament

        expect(TwilightStruggle::Tournament.find_by(external_id:).parent).to eq(parent)
      end
    end

    context "with a parent_external_id referencing an unknown tournament" do
      let(:params) { {tournament: {name: "Child", parent_external_id: "does-not-exist"}} }

      it "returns 422" do
        put_tournament

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a tournament row" do
        expect { put_tournament }.not_to change(TwilightStruggle::Tournament, :count)
      end
    end

    context "with a blank name" do
      let(:params) { {tournament: {name: ""}} }

      it "returns 422 with an errors array" do
        put_tournament

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to be_present
      end
    end

    context "with a whitespace-only name that the schema lets through" do
      let(:params) { {tournament: {name: "   "}} }

      it "returns 422 from the model validation with an errors array" do
        put_tournament

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to be_present
      end

      it "does not create a tournament row" do
        expect { put_tournament }.not_to change(TwilightStruggle::Tournament, :count)
      end
    end
  end

  describe "DELETE /api/twilight-struggle/v1/tournaments/:external_id" do
    subject(:delete_tournament) do
      delete api_twilight_struggle_v1_tournament_path(external_id), headers:
    end

    context "when the tournament exists" do
      let!(:tournament) { create(:twilight_struggle_tournament, external_id:) }

      it "returns 204" do
        delete_tournament

        expect(response).to have_http_status(:no_content)
      end

      it "deletes the row" do
        expect { delete_tournament }.to change(TwilightStruggle::Tournament, :count).by(-1)
      end
    end

    context "when the external_id does not exist" do
      it "returns 204" do
        delete_tournament

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
