# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Http do
  subject(:get_json) do
    described_class.get_json(url, params:, headers:, status_errors:) { |body| body.fetch("value") }
  end

  let(:url) { "https://example.test/api/data" }
  let(:params) { {} }
  let(:headers) { {} }
  let(:status_errors) { {} }
  let(:status) { "200" }
  let(:body) { {"value" => 42}.to_json }
  let(:retry_after) { nil }
  let(:response) { instance_double(Net::HTTPResponse, code: status, body:) }
  let(:http) { instance_double(Net::HTTP) }
  let(:sent_requests) { [] }

  before do
    allow(response).to receive(:[]).with("Retry-After").and_return(retry_after)
    allow(response).to receive(:to_hash).and_return({"ratelimit-reset" => ["1793361645"]})
    allow(Net::HTTP).to receive(:start).and_yield(http).and_return(response)
    allow(http).to receive(:request) do |request|
      sent_requests << request
      response
    end
  end

  context "when the provider responds 2xx" do
    it "returns what the block makes of the parsed body" do
      expect(get_json).to eq(42)
    end

    it "connects over TLS with bounded timeouts and no silent retry" do
      get_json

      expect(Net::HTTP).to have_received(:start).with(
        "example.test",
        443,
        use_ssl: true,
        open_timeout: 5,
        read_timeout: 15,
        max_retries: 0
      )
    end

    it "asks for JSON and identifies shrkbot" do
      get_json

      expect(sent_requests.first.to_hash).to include(
        "user-agent" => ["shrkbot (+https://shrkbot.com)"],
        "accept" => ["application/json"]
      )
    end

    context "with extra headers" do
      let(:headers) { {"Client-Id" => "abc", "Authorization" => "Bearer xyz"} }

      it "sends them next to the defaults" do
        get_json

        expect(sent_requests.first.to_hash).to include(
          "client-id" => ["abc"],
          "authorization" => ["Bearer xyz"],
          "user-agent" => ["shrkbot (+https://shrkbot.com)"]
        )
      end
    end

    context "with params" do
      let(:params) { {q: "a b", n: 1} }

      it "sends them as an encoded query string" do
        get_json

        expect(sent_requests.first.path).to eq("/api/data?q=a+b&n=1")
      end
    end

    context "without params" do
      it "sends no query string" do
        get_json

        expect(sent_requests.first.path).to eq("/api/data")
      end
    end

    context "when the URL is plain http" do
      let(:url) { "http://example.test/api/data" }

      it "connects without TLS" do
        get_json

        expect(Net::HTTP).to have_received(:start).with("example.test", 80, hash_including(use_ssl: false))
      end
    end

    context "when the block needs a key the response lacks" do
      let(:body) { {"other" => 1}.to_json }

      it "raises Unavailable, because the provider changed its response" do
        expect { get_json }.to raise_error(Integrations::Unavailable, /example\.test/)
      end
    end

    context "when the body is not JSON" do
      let(:body) { "<html>maintenance</html>" }

      it "raises Unavailable" do
        expect { get_json }.to raise_error(Integrations::Unavailable)
      end
    end

    context "when the body is null where the block expects an object" do
      let(:body) { "null" }

      it "raises Unavailable, because the provider changed its response" do
        expect { get_json }.to raise_error(Integrations::Unavailable, /changed its response/)
      end
    end

    context "when the body is an array where the block expects an object" do
      let(:body) { [1, 2].to_json }

      it "raises Unavailable, because the provider changed its response" do
        expect { get_json }.to raise_error(Integrations::Unavailable, /changed its response/)
      end
    end
  end

  {
    401 => Integrations::Unauthorized,
    403 => Integrations::Unauthorized,
    404 => Integrations::NotFound,
    410 => Integrations::NotFound,
    500 => Integrations::Unavailable,
    503 => Integrations::Unavailable,
    400 => Integrations::Error,
    302 => Integrations::Error
  }.each do |code, error_class|
    context "when the provider responds #{code}" do
      let(:status) { code.to_s }

      it "raises exactly #{error_class}, naming the host and status" do
        expect { get_json }.to raise_error(
          an_instance_of(error_class).and(having_attributes(message: "example.test responded #{code}"))
        )
      end
    end
  end

  context "when the provider responds 429" do
    let(:status) { "429" }

    context "with a Retry-After in seconds" do
      let(:retry_after) { "120" }

      it "raises RateLimited carrying the seconds" do
        expect { get_json }.to raise_error(Integrations::RateLimited) { |error| expect(error.retry_after).to eq(120) }
      end
    end

    context "with a Retry-After that has a leading zero" do
      let(:retry_after) { "0120" }

      it "reads it as decimal seconds, not octal" do
        expect { get_json }.to raise_error(Integrations::RateLimited) { |error| expect(error.retry_after).to eq(120) }
      end
    end

    context "with a Retry-After as an HTTP date" do
      let(:retry_after) { "Wed, 21 Oct 2026 07:28:00 GMT" }

      it "raises RateLimited without a retry_after" do
        expect { get_json }.to raise_error(Integrations::RateLimited) { |error| expect(error.retry_after).to be_nil }
      end
    end

    context "without a Retry-After header" do
      it "raises RateLimited without a retry_after" do
        expect { get_json }.to raise_error(Integrations::RateLimited) { |error| expect(error.retry_after).to be_nil }
      end
    end

    it "carries the response headers for a provider-specific reset header" do
      expect { get_json }.to raise_error(Integrations::RateLimited) do |error|
        expect(error.headers).to eq({"ratelimit-reset" => ["1793361645"]})
      end
    end
  end

  context "when the caller overrides a status" do
    let(:status_errors) { {403 => Integrations::NotFound} }

    context "and the provider responds with that status" do
      let(:status) { "403" }

      it "raises the override instead of the default" do
        expect { get_json }.to raise_error(an_instance_of(Integrations::NotFound))
      end
    end

    context "and the provider responds with another default-mapped status" do
      let(:status) { "401" }

      it "keeps the default mapping" do
        expect { get_json }.to raise_error(an_instance_of(Integrations::Unauthorized))
      end
    end
  end

  [
    Net::OpenTimeout,
    Net::ReadTimeout,
    SocketError,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::ETIMEDOUT,
    Errno::EHOSTUNREACH,
    EOFError,
    OpenSSL::SSL::SSLError,
    Net::HTTPBadResponse,
    Net::HTTPHeaderSyntaxError,
    Net::ProtocolError,
    Zlib::DataError
  ].each do |network_error|
    context "when the connection fails with #{network_error}" do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(network_error)
      end

      it "raises Unavailable naming the host" do
        expect { get_json }.to raise_error(Integrations::Unavailable, /\Aexample\.test: /)
      end
    end
  end

  describe ".post_form" do
    subject(:post_form) do
      described_class.post_form(url, form: {a: "1", b: "x y"}) { |body| body.fetch("value") }
    end

    it "posts the form-encoded body and yields the parsed JSON" do
      expect(post_form).to eq(42)
      expect(sent_requests.first.method).to eq("POST")
      expect(sent_requests.first.body).to eq("a=1&b=x+y")
      expect(sent_requests.first["Content-Type"]).to eq("application/x-www-form-urlencoded")
    end

    context "when the provider responds 400" do
      let(:status) { "400" }

      subject(:post_form) do
        described_class.post_form(url, form: {a: "1"}, status_errors: {400 => Integrations::Unauthorized}) { |body| body }
      end

      it "raises the mapped error" do
        expect { post_form }.to raise_error(an_instance_of(Integrations::Unauthorized))
      end
    end
  end

  describe ".post_json" do
    subject(:post_json) do
      described_class.post_json(url, body: {type: "x", n: 1}, headers: {"Client-Id" => "abc"}) do |parsed|
        parsed.fetch("value")
      end
    end

    it "posts the JSON body with its content type and headers, yielding the parsed JSON" do
      expect(post_json).to eq(42)
      expect(sent_requests.first.method).to eq("POST")
      expect(JSON.parse(sent_requests.first.body)).to eq({"type" => "x", "n" => 1})
      expect(sent_requests.first["Content-Type"]).to eq("application/json")
      expect(sent_requests.first["Client-Id"]).to eq("abc")
    end
  end

  describe ".delete" do
    subject(:delete) { described_class.delete(url, params: {id: "7"}, headers: {"Client-Id" => "abc"}) }

    let(:body) { nil }

    it "sends DELETE with the query and headers, and returns nil" do
      expect(delete).to be_nil
      expect(sent_requests.first.method).to eq("DELETE")
      expect(sent_requests.first.path).to eq("/api/data?id=7")
      expect(sent_requests.first["Client-Id"]).to eq("abc")
    end

    context "when the provider responds 404" do
      let(:status) { "404" }

      it "raises NotFound" do
        expect { delete }.to raise_error(Integrations::NotFound)
      end
    end

    context "when the connection fails" do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
      end

      it "raises Unavailable naming the host" do
        expect { delete }.to raise_error(Integrations::Unavailable, /\Aexample\.test: /)
      end
    end
  end

  describe ".get_bytes" do
    subject(:get_bytes) { described_class.get_bytes(url) }

    let(:url) { "https://img.test/a/hero.jpg?t=17" }
    let(:body) { "\xFF\xD8bytes".b }

    it "returns the raw body" do
      expect(get_bytes).to eq(body)
    end

    it "keeps the URL's own query string and accepts any type" do
      get_bytes

      expect(sent_requests.first.path).to eq("/a/hero.jpg?t=17")
      expect(sent_requests.first["accept"]).to eq("*/*")
    end

    context "when the body is over the size cap" do
      let(:body) { "a" * (described_class::MAX_BYTES + 1) }

      it "raises Unavailable naming the host" do
        expect { get_bytes }.to raise_error(Integrations::Unavailable, /\Aimg\.test sent more than/)
      end
    end

    context "when the connection fails" do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
      end

      it "raises Unavailable naming the host" do
        expect { get_bytes }.to raise_error(Integrations::Unavailable, /\Aimg\.test: /)
      end
    end

    context "when the host responds 404" do
      let(:status) { "404" }

      it "raises NotFound" do
        expect { get_bytes }.to raise_error(Integrations::NotFound)
      end
    end
  end
end
