# Everything in the engine except its initializer, so the parts can be used
# (and tested) without booting a site. lib/nibble_site.rb loads this.
require "bridgetown"
require "erb"
require "json"
require "net/http"

require_relative "version"
require_relative "options"
require_relative "places"
require_relative "structured_data"
require_relative "seo"
require_relative "google_reviews"
require_relative "rack/canonical_host"
require_relative "rack/static_headers"
require_relative "rack/endpoints"
require_relative "builders/data"
require_relative "builders/samples"
require_relative "builders/website_locations"
require_relative "builders/location_pages"
require_relative "builders/helpers"

module NibbleSite
  CONTENT_DIR = File.expand_path("../../content", __dir__)
end
