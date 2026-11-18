module NibbleSite
  module Builders
    # A page for each location at /locations/<slug>/, laid out by the site's
    # src/_layouts/location.erb (which finds its location by
    # `location_slug`). A location switched on in Nibble gets its page on the
    # next build; one switched off loses it.
    #
    # Its title and description come from the options (NibbleSite::Options);
    # its sharing picture is the location's photo.
    class LocationPages < Bridgetown::Builder
      def build
        generator do
          business = site.data.nibble.business&.name.to_s
          Array(site.data.nibble.locations).each do |location|
            words = {name: location.name, place: Places.place_of(location), business: business}
            page_title = format(NibbleSite.options.location_title, **words)
            # With no place, "at Kilcoole, ." becomes "at Kilcoole."
            page_description = format(NibbleSite.options.location_description, **words).sub(/,\s*\./, ".").slice(0, 160)
            add_resource :pages, "locations/#{location.slug}.erb" do
              layout "location"
              permalink Places.path_for(location)
              location_slug location.slug
              title page_title
              description page_description
              share_image location.photo
              share_url location.photo_url
              content ""
            end
          end
        end
      end
    end
  end
end
