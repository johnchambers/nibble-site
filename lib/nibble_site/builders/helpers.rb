module NibbleSite
  module Builders
    # The helpers the site's templates use. The business's data is in
    # site.data.nibble: business.yml, packages.yml and appearances.yml from
    # the site, and the locations and menus from Nibble (or the local files
    # before the business is in Nibble).
    #
    # Helper blocks run on this builder, not in the template, so one helper
    # can't call another; anything shared is a method below.
    class Helpers < Bridgetown::Builder
      include StructuredData
      include Seo

      NavLink = Struct.new(:label, :url)

      def build
        helper(:euro) { |cents, from: false| Places.euro(cents, from:) }

        # --- Search, sharing and AI (NibbleSite::Seo, NibbleSite::StructuredData)

        # The title, description, canonical link, robots, sharing tags and
        # structured data for a page's <head>.
        helper(:nibble_head_tags) { |resource| head_tags(resource) }
        # Just the structured data: a list of schema.org objects.
        helper(:structured_data) { |resource| schema_for(resource) }

        # --- Locations (Nibble's outlets)

        helper(:locations) { all_locations }
        helper(:location_path) { |location| Places.path_for(location) }
        # Its ordering page: the Nibble storefront's page for that location.
        helper(:location_order_url) { |location| order_url_for(location) }
        # The business's ordering page: business.yml `order_url`, or its
        # Nibble storefront.
        helper(:order_online_url) { business_order_url }
        helper(:location_place) { |location| Places.place_of(location) }
        helper(:location_address_lines) { |location| Places.address_lines(location) }
        helper(:location_maps_url) { |location| Places.maps_url(location) }
        helper(:location_menus) { |location| Places.menus_for(location, site.data.nibble.menus) }
        helper(:menu_locations) { |menu| all_locations.select { |l| Places.menus_for(l, site.data.nibble.menus).any? { |m| m.id.to_s == menu.id.to_s } } }
        helper(:weekly_hours) { |location| Places.week_of(location) }
        helper(:hours_summary) { |location| Places.summary_of(location) }
        helper(:upcoming_special_hours) { |location| Places.special_dates(location) }

        # --- Festival dates (appearances.yml)

        # Upcoming dates, soonest first.
        helper(:upcoming_appearances) { upcoming }

        # "Sat 5 June 2027", or "30 January – 1 February 2027" for several days.
        helper :appearance_dates do |a|
          starts, ends = a.starts_on, a.ends_on
          if ends.nil? || ends == starts
            starts.strftime("%a %-d %B %Y")
          elsif starts.month == ends.month
            "#{starts.day}–#{ends.strftime("%-d %B %Y")}"
          else
            "#{starts.strftime("%-d %B")} – #{ends.strftime("%-d %B %Y")}"
          end
        end

        # --- The business

        # "Wicklow, Wexford and South Dublin"
        helper(:areas_sentence) { areas_sentence }

        helper :packages_for do |kind|
          Array(site.data.nibble.packages).select { |p| Array(p.kind).include?(kind) }
        end

        helper :whatsapp_url do |text = nil|
          number = site.data.nibble.business.contact&.whatsapp
          text ? "https://wa.me/#{number}?text=#{ERB::Util.url_encode(text)}" : "https://wa.me/#{number}"
        end

        # A menu item's dropdown (navigation.yml): its children, with every
        # location first when it says `with_locations`.
        helper :nav_children do |item|
          kids = Array(item.children).map { |c| NavLink.new(c.label, c.url) }
          kids = all_locations.map { |l| NavLink.new(l.name, Places.path_for(l)) } + kids if item.with_locations
          kids
        end
      end

      private

      def all_locations
        Array(site.data.nibble.locations)
      end

      def upcoming(today = Date.today)
        Array(site.data.nibble.appearances)
          .select { |a| (a.ends_on || a.starts_on) >= today }
          .sort_by(&:starts_on)
      end

      def areas_sentence
        areas = Array(site.data.nibble.business.areas_served)
        (areas.size > 1) ? "#{areas[0..-2].join(", ")} and #{areas.last}" : areas.first.to_s
      end

      # A location's ordering page: the one the Nibble API sends, or the
      # business's with /at/<slug>.
      def order_url_for(location)
        location.order_url || "#{business_order_url}/at/#{location.slug}"
      end

      # business.yml `order_url` (for ordering on the business's own domain,
      # once that's built), or the Nibble storefront: nibble.ie/<slug>.
      def business_order_url
        own = site.data.nibble.business.order_url
        return own.to_s.strip.delete_suffix("/") unless Places.blank?(own)

        nibble = ENV.fetch("NIBBLE_API_URL", "").strip.delete_suffix("/")
        nibble = "https://nibble.ie" if nibble.empty?
        "#{nibble}/#{Data.slug(site)}"
      end
    end
  end
end
