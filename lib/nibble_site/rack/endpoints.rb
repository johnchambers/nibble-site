require "yaml"

module NibbleSite
  module Rack
    # Rack middleware (config.ru) answering the few addresses that aren't
    # pages:
    #
    #   /up            "OK", for Hatchbox's health check
    #   /reviews.json  the business's live Google rating and review count
    #                  (NibbleSite::GoogleReviews); 204 when there isn't one
    #   old addresses  a permanent redirect from the business's old website's
    #                  addresses to the pages that replaced them, so links
    #                  and search rankings carry over
    #
    # The old addresses are in the site's src/_data/redirects.yml:
    #
    #   pages:                       # an exact address
    #     page/about-us: /about/
    #   prefixes:                    # everything starting with it
    #     product/: /menu/
    #
    # Paths are without the leading slash; a trailing slash doesn't matter.
    # In production Caddy serves the built pages before a request gets
    # here, so an old address only redirects while no page has the same
    # path.
    class Endpoints
      def initialize(app, redirects: File.join(Dir.pwd, "src/_data/redirects.yml"))
        @app = app
        moved = File.exist?(redirects) ? (YAML.safe_load_file(redirects) || {}) : {}
        @pages = (moved["pages"] || {}).transform_keys { |path| tidy(path) }
        @prefixes = (moved["prefixes"] || {}).sort_by { |prefix, _| -prefix.length }
      end

      def call(env)
        path = env["PATH_INFO"].to_s
        return [200, {"content-type" => "text/plain"}, ["OK"]] if path == "/up"
        return reviews if path == "/reviews.json"

        target = moved_to(tidy(path))
        return @app.call(env) unless target

        [301, {"location" => target, "content-type" => "text/plain", "cache-control" => "public, max-age=3600"}, ["Moved to #{target}\n"]]
      end

      private

      def tidy(path)
        path.to_s.delete_prefix("/").delete_suffix("/")
      end

      def moved_to(path)
        return nil if path.empty?

        @pages[path] || @prefixes.find { |prefix, _| path.start_with?(prefix) }&.last
      end

      def reviews
        found = GoogleReviews.current
        return [204, {"content-type" => "application/json"}, []] unless found

        [200, {"content-type" => "application/json", "cache-control" => "public, max-age=3600"}, [JSON.generate(found)]]
      end
    end
  end
end
