# Run as `nibble-site google-place-id` from a site's folder.
# Finds a business's Google place ID, for GOOGLE_PLACE_ID.
#
#   GOOGLE_PLACES_API_KEY=... nibble-site google-place-id "<name> <town>"
#
# Prints each match with its address and review count, so the right one is
# easy to pick.

require "json"
require "net/http"

key = ENV["GOOGLE_PLACES_API_KEY"].to_s.strip
abort "Set GOOGLE_PLACES_API_KEY first." if key.empty?
query = ARGV.join(" ").strip
abort "Say what to search for: nibble-site google-place-id \"<name> <town>\"" if query.empty?

uri = URI("https://places.googleapis.com/v1/places:searchText")
request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
request["X-Goog-Api-Key"] = key
request["X-Goog-FieldMask"] = "places.id,places.displayName,places.formattedAddress,places.rating,places.userRatingCount"
request.body = JSON.generate(textQuery: query, regionCode: "IE")
response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
abort "Google answered #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

places = JSON.parse(response.body)["places"] || []
abort "Nothing found for \"#{query}\"." if places.empty?

places.each do |place|
  puts place.dig("displayName", "text")
  puts "  #{place["formattedAddress"]}"
  puts "  #{place["userRatingCount"] || 0} reviews, rated #{place["rating"] || "-"}"
  puts "  GOOGLE_PLACE_ID=#{place["id"]}"
  puts
end
