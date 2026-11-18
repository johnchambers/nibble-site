module NibbleSite
  module Rack
    # Rack middleware in front of the site's Roda app (config.ru).
    #
    # 1. HEAD requests are served as GET with an empty body. Bridgetown's static
    #    file server only routes GET, so without this an uptime monitor's HEAD /
    #    would fall through to the app redirect.
    # 2. Successful static responses get cache and security headers. The static
    #    server replaces the response headers wholesale, so Roda's default_headers
    #    plugin never reaches them; setting them here does.
    class StaticHeaders
      IMMUTABLE_PATH = %r{\A/_bridgetown/static/}

      def initialize(app)
        @app = app
      end

      def call(env)
        head = env["REQUEST_METHOD"] == "HEAD"
        env["REQUEST_METHOD"] = "GET" if head

        status, headers, body = @app.call(env)

        if status == 200
          headers["cache-control"] ||= env["PATH_INFO"].match?(IMMUTABLE_PATH) ? "public, max-age=31536000, immutable" : "public, max-age=300"
          headers["x-content-type-options"] ||= "nosniff"
          headers["x-frame-options"] ||= "SAMEORIGIN"
          headers["referrer-policy"] ||= "strict-origin-when-cross-origin"
        end

        if head
          body.close if body.respond_to?(:close)
          body = []
        end

        [status, headers, body]
      end
    end
  end
end
