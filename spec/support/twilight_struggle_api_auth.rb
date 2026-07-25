# frozen_string_literal: true

RSpec.shared_context "twilight struggle api auth" do
  let(:headers) { {"Authorization" => "Bearer key-one"} }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("TWILIGHT_STRUGGLE_API_KEYS", "").and_return("key-one,key-two")
  end
end
