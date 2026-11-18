module NibbleSite
  module Rack
    # Rack middleware (config.ru): when SITE_CANONICAL_HOST is set (for example
    # www.theirbusiness.ie), any request for another hostname, such as the bare
    # theirbusiness.ie, is answered with a permanent redirect to the same path on
    # the canonical host, so search engines see one copy of the site. /up is
    # exempt so the Hatchbox health check still succeeds.
    class CanonicalHost
      def initialize(app)
        @app = app
        @canonical = ENV.fetch("SITE_CANONICAL_HOST", "").strip.downcase
      end

      def call(env)
        return @app.call(env) if @canonical.empty?

        request = ::Rack::Request.new(env)
        return @app.call(env) if request.path == "/up" || request.host.to_s.downcase == @canonical

        target = "https://#{@canonical}#{request.fullpath}"
        [301, {"location" => target, "content-type" => "text/plain", "cache-control" => "public, max-age=3600"}, ["Moved to #{target}\n"]]
      end
    end
  end
end
