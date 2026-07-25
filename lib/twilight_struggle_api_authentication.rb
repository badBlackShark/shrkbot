# frozen_string_literal: true

# Rack middleware that fails closed on the bearer token before any downstream
# middleware (notably committee's schema validation) runs, so an unauthenticated
# request never reaches — or reveals — the request contract. Scoped to the
# Twilight Struggle API path; everything else passes straight through.
class TwilightStruggleApiAuthentication
  PREFIX = "/api/twilight-struggle/v1"

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless env["PATH_INFO"].to_s.start_with?(PREFIX)
    return unauthorized unless authorized?(env)

    @app.call(env)
  end

  private

  def authorized?(env)
    token = env["HTTP_AUTHORIZATION"].to_s[/\ABearer (.+)\z/, 1]
    token.present? && keys.any? { |key| ActiveSupport::SecurityUtils.secure_compare(token, key) }
  end

  def keys
    ENV.fetch("TWILIGHT_STRUGGLE_API_KEYS", "").split(",").map(&:strip).reject(&:empty?)
  end

  def unauthorized
    [401, {"WWW-Authenticate" => %(Bearer realm="Twilight Struggle API")}, []]
  end
end
