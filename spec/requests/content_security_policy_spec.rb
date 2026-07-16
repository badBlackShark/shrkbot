# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Content Security Policy", type: :request do
  subject(:header) { response.headers["Content-Security-Policy"] }

  before { get root_path }

  it "enforces a script-src of self plus a per-request nonce" do
    expect(header).to match(/script-src 'self' 'nonce-[^']+'/)
  end

  it "locks down the risky directives" do
    expect(header).to include("default-src 'self'")
    expect(header).to include("object-src 'none'")
    expect(header).to include("base-uri 'self'")
    expect(header).to include("form-action 'self'")
  end

  it "allows Discord's CDN for images and inline styles for dynamic colours" do
    expect(header).to include("img-src 'self' data: https://cdn.discordapp.com https://media.discordapp.net")
    expect(header).to include("style-src 'self' 'unsafe-inline'")
  end

  it "stamps the inline theme script and the importmap with the header's nonce" do
    nonce = header[/script-src 'self' 'nonce-([^']+)'/, 1]

    expect(response.body).to include(%(<script nonce="#{nonce}">))
    expect(response.body).to match(/<script type="importmap"[^>]*nonce="#{Regexp.escape(nonce)}"/)
  end
end
