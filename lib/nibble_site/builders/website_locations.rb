module NibbleSite
  module Builders
    # Tidies the locations for the website once they're read, from the API
    # or the local file:
    #
    # - A location with no address and no opening hours is left off. It's
    #   somewhere the business sells (an events truck, say), not somewhere a
    #   customer can find them, so its card could only say "Closed". Give it
    #   an address or hours in Nibble and it appears.
    # - The county reads "Co. Wicklow", however it was typed.
    class WebsiteLocations < Bridgetown::Builder
      def build
        # After Data has put the API's answer in place.
        hook :site, :post_read, priority: :low do |site|
          nibble = site.data.nibble
          next unless nibble[:locations]

          findable, hidden = Array(nibble[:locations]).partition { |l| Places.findable?(l) }
          findable.each { |l| l.address.county = Places.county_name(l.address.county) if l.address }
          nibble[:locations] = findable
          hidden.each { |l| Bridgetown.logger.info "Locations:", "left off #{l.name}: no address and no opening hours" }
        end
      end
    end
  end
end
