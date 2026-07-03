# frozen_string_literal: true

RSpec.shared_context "discord auth" do
  let(:auth) do
    OmniAuth::AuthHash.new(
      provider: "discord",
      uid: "12345",
      info: {name: "shrk"},
      credentials: {token: "discord-access-token"}
    )
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:discord] = auth
    Rails.application.env_config["omniauth.auth"] = auth
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:discord] = nil
    Rails.application.env_config.delete("omniauth.auth")
  end
end
