# The engine behind Nibble's bespoke websites for food businesses.
#
# A site adds it to its Gemfile and turns it on in config/initializers.rb:
#
#   init :nibble_site, location_title: "Pizza at %{name}"
#
# It then reads the business's details from src/_data/nibble/ (and its
# locations and menus from the Nibble API when NIBBLE_API_URL is set), makes
# a page for each location, gives the templates their helpers, and adds the
# sitemap, robots.txt, llms.txt and the search and sharing tags. Everything a
# visitor sees (layouts, partials, styles, JavaScript) stays in the site, so
# each one keeps its own design. See README.md.
require_relative "nibble_site/core"

Bridgetown.initializer :nibble_site do |config, **options|
  NibbleSite.options = NibbleSite::Options.new(**options)

  # Until launch every page says noindex and robots.txt turns crawlers away,
  # and sample data is shown, labelled. SITE_LIVE=1 on the live site only.
  config.site_live ENV["SITE_LIVE"] == "1"

  # sitemap.xml, robots.txt and llms.txt.
  config.source_manifest origin: NibbleSite, contents: {pages: NibbleSite::CONTENT_DIR}

  config.builder NibbleSite::Builders::Data
  config.builder NibbleSite::Builders::Samples
  config.builder NibbleSite::Builders::WebsiteLocations
  config.builder NibbleSite::Builders::LocationPages
  config.builder NibbleSite::Builders::Helpers
end
