# frozen_string_literal: true

require "rails_helper"
require "sentry/test_helper"

RSpec.describe SentryHttpScrubber do
  let!(:server) { TCPServer.new("127.0.0.1", 0) }
  let(:origin) { "http://127.0.0.1" }
  let(:request_uri) { "/attachments/1/2/secret-name.png?ex=abc&hm=def" }

  describe "an outgoing request recorded by the SDK" do
    include Sentry::TestHelper

    subject(:perform) do
      transaction = Sentry.start_transaction(name: "spec")
      Sentry.get_current_scope.set_span(transaction)
      Net::HTTP.start("127.0.0.1", server.addr[1]) { |http| http.get(request_uri) }
      transaction.finish
    end

    let(:event) { sentry_events.find { |sent| sent.is_a?(Sentry::TransactionEvent) } }
    let(:http_span) { event.spans.find { |span| span[:op] == "http.client" } }
    let(:breadcrumb) { Sentry.get_current_scope.breadcrumbs.peek }

    let!(:original_client) { Sentry.get_current_client }

    before do
      setup_sentry_test
      Thread.new do
        client = server.accept
        client.gets("\r\n\r\n")
        client.write("HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
        client.close
      end
    end

    after do
      teardown_sentry_test
      Sentry.get_main_hub.bind_client(original_client)
      server.close
    end

    it "leaves a breadcrumb with only the method, status and origin" do
      perform
      expect(breadcrumb.data).to eq(method: "GET", status: 200, url: origin)
    end

    it "leaves a span whose description and data carry only the origin" do
      perform
      expect(http_span.slice(:description, :data)).to include(
        description: "GET #{origin}",
        data: include("url" => origin)
      )
    end

    it "leaves no query in the span data" do
      perform
      expect(http_span[:data]).not_to have_key("http.query")
    end
  end

  describe ".breadcrumb" do
    subject(:scrubbed) { described_class.breadcrumb(crumb) }

    let(:category) { "net.http" }
    let(:data) { {status: 200, method: "POST", url: "https://discord.com/api/v10/interactions/1/token/callback", query: "a=1", body: "x"} }
    let(:crumb) { Sentry::Breadcrumb.new(category:, data:) }

    it "keeps the method and status and cuts the URL to its origin" do
      expect(scrubbed.data).to eq(status: 200, method: "POST", url: "https://discord.com")
    end

    context "with a breadcrumb from another source" do
      let(:category) { "active_support" }
      let(:data) { {query: "kept", url: "https://x.test/path"} }

      it "returns the data unchanged" do
        expect(scrubbed.data).to eq(query: "kept", url: "https://x.test/path")
      end
    end
  end
end
