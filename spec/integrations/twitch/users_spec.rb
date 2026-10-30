# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Users do
  subject(:user) { users.find_by_login("twitchdev") }

  let(:users) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Twitch::Client) }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/twitch/users_twitchdev.json").read) }

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "looks the channel up by login" do
    user

    expect(client).to have_received(:get_json).with("/users", params: {login: "twitchdev"})
  end

  it "returns the user" do
    expect(user).to eq(
      Integrations::Twitch::User.new(
        id: "141981764",
        login: "twitchdev",
        display_name: "TwitchDev",
        profile_image_url: "https://static-cdn.jtvnw.net/jtv_user_pictures/8a6381c7-d0c0-4576-b179-38bd5ce1d6af-profile_image-300x300.png"
      )
    )
  end

  context "when Twitch has no such login" do
    let(:response) { {"data" => []} }

    it "raises NotFound naming the login" do
      expect { user }.to raise_error(Integrations::NotFound, "Twitch has no channel twitchdev")
    end
  end
end
