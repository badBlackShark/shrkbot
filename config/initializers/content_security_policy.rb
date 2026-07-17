# frozen_string_literal: true

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri :self
    policy.font_src :self, :data
    policy.form_action :self
    policy.img_src :self, :data, "https://cdn.discordapp.com", "https://media.discordapp.net"
    policy.object_src :none
    policy.script_src :self
    policy.style_src :self, :unsafe_inline
  end

  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
