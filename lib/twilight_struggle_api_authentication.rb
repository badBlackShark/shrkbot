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
    path = routed_path(env)
    return @app.call(env) unless path.start_with?(PREFIX)
    return unauthorized unless authorized?(env)

    env["PATH_INFO"] = path
    @app.call(env)
  end

  private

  # The router squeezes repeated slashes before it matches, so "/api//twilight-struggle/v1/…"
  # reaches the API controllers without starting with PREFIX. Compare the path the router will see.
  def routed_path(env)
    ActionDispatch::Journey::Router::Utils.normalize_path(env["PATH_INFO"])
  end

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
