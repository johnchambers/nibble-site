module NibbleSite
  # The business's Google rating and review count, live from the Google
  # Places API, for /reviews.json (NibbleSite::Rack::Endpoints).
  #
  # The pages are built ahead of time with the count from
  # src/_data/nibble/business.yml; the site's google-reviews controller asks
  # /reviews.json for the current one when the page loads, so the count keeps
  # up without a rebuild. It's fetched here, on the server, so the API key
  # never reaches the browser, and kept for a few hours so a busy day costs a
  # handful of calls (Google's free allowance covers them).
  #
  # Needs GOOGLE_PLACES_API_KEY and GOOGLE_PLACE_ID (find the ID with
  # `nibble-site google-place-id`). Without them, or when Google doesn't
  # answer, there's nothing to give and the page keeps its built-in count.
  class GoogleReviews
    KEEP_FOR = 6 * 60 * 60 # seconds
    FIELDS = "rating,userRatingCount,googleMapsUri,googleMapsLinks.reviewsUri".freeze

    @mutex = Mutex.new
    @kept = nil
    @kept_at = nil

    class << self
      # @return [Hash, nil] {count:, rating:, url:}, or nil when unknown
      def current
        return nil unless configured?

        @mutex.synchronize do
          if @kept_at.nil? || Time.now - @kept_at > KEEP_FOR
            fresh = fetch
            # A failed call keeps the last good answer, and tries again in a
            # few minutes rather than on every page view.
            @kept = fresh if fresh
            @kept_at = fresh ? Time.now : Time.now - KEEP_FOR + 300
          end
          @kept
        end
      end

      def configured?
        !ENV["GOOGLE_PLACES_API_KEY"].to_s.strip.empty? && !ENV["GOOGLE_PLACE_ID"].to_s.strip.empty?
      end

      private

      def fetch
        uri = URI("https://places.googleapis.com/v1/places/#{ENV["GOOGLE_PLACE_ID"].strip}")
        request = Net::HTTP::Get.new(uri)
        request["X-Goog-Api-Key"] = ENV["GOOGLE_PLACES_API_KEY"].strip
        request["X-Goog-FieldMask"] = FIELDS
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
          http.request(request)
        end
        unless response.is_a?(Net::HTTPSuccess)
          warn "GoogleReviews: Google answered #{response.code}"
          return nil
        end

        place = JSON.parse(response.body)
        return nil unless place["userRatingCount"]

        {
          count: place["userRatingCount"],
          rating: place["rating"],
          url: place.dig("googleMapsLinks", "reviewsUri") || place["googleMapsUri"]
        }
      rescue StandardError => e
        warn "GoogleReviews: #{e.class}: #{e.message}"
        nil
      end
    end
  end
end
