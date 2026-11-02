# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::Discord::Rest do
  subject(:get) { described_class.get("/users/999", authorization: "Bot t") }

  let(:http) { instance_double(Net::HTTP) }
  let(:response) { instance_double(Net::HTTPResponse) }

  before do
    allow(http).to receive(:request).and_return(response)
    allow(Net::HTTP).to receive(:start).and_yield(http).and_return(response)
  end

  it "never lets Net::HTTP resend a stalled request" do
    get

    expect(Net::HTTP).to have_received(:start).with("discord.com", 443, hash_including(max_retries: 0, open_timeout: 5, read_timeout: 5))
  end

  it "identifies itself the way Discord asks bots to" do
    get

    expect(http).to have_received(:request).with(
      satisfy { |request| request["User-Agent"].start_with?("DiscordBot (#{ReleaseInfo::REPO_URL}, ") && request["Authorization"] == "Bot t" }
    )
  end

  context "without a released version" do
    before do
      allow(ReleaseInfo).to receive(:current).and_return(nil)
    end

    it "still sends a valid bot User-Agent" do
      get

      expect(http).to have_received(:request).with(satisfy { |request| request["User-Agent"] == "DiscordBot (#{ReleaseInfo::REPO_URL}, 0)" })
    end
  end
end
