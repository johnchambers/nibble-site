module NibbleSite
  # schema.org structured data (JSON-LD) for every page, for search engines
  # and AI assistants. Included in Builders::Helpers, so it can use that
  # builder's location and order-link methods.
  #
  # What each page says:
  #   every page      the business, and breadcrumbs
  #   home            the WebSite, which is how Google learns the site's name
  #   location pages  that location as a place of its own: address, map
  #                   position, weekly and holiday hours, price range, menu
  #                   and order-ahead link, belonging to the business
  #   `kind` pages    a page with `kind` in its front matter (weddings,
  #                   parties...) is a catering service, with the packages
  #                   of that kind as offers
  #   FAQs            any page with `faqs` ([{q, a}]) in its front matter
  #   menu page       the whole menu, with prices (`menu_schema: true`)
  #   festivals       each upcoming festival date (`events_schema: true`)
  #
  # Never mark up the site's own testimonials as reviews or a star rating:
  # Google ignores ratings a business publishes about itself, and the stars
  # in search come from its Google Business Profile.
  module StructuredData
      def schema_for(resource)
        d = resource.data
        graphs = [business_schema]
        graphs << website_schema if resource.relative_url == "/"
        here = d.location_slug && all_locations.find { |l| l.slug == d.location_slug }
        crumbs = breadcrumbs_schema(resource, here)
        graphs << crumbs if crumbs
        graphs << location_schema(here) if here
        graphs << service_schema(resource) if d.kind
        graphs << faq_schema(d.faqs) if d.faqs && !Array(d.faqs).empty?
        graphs << menu_schema if d.menu_schema
        graphs.concat(festival_schemas) if d.events_schema
        graphs.map { |graph| {"@context" => "https://schema.org"}.merge(graph) }
      end

      private

      def base_url
        site.config.url
      end

      def business_id
        "#{base_url}/#business"
      end

      def nibble_business
        site.data.nibble.business
      end

      def area_served
        Array(nibble_business.areas_served).map do |area|
          # "Wicklow" is County Wicklow; "South Dublin" stays as it is.
          {"@type" => "AdministrativeArea", "name" => area.to_s.include?(" ") ? area : "County #{area}"}
        end
      end

      # "520.00"
      def decimal(cents)
        format("%.2f", cents / 100.0)
      end

      # "€2.50–€18" across the menus' prices, or nil with no prices.
      def price_range(menus)
        prices = menu_items(menus).filter_map(&:price_cents)
        return nil if prices.empty?

        low, high = prices.minmax.map { |c| c % 100 == 0 ? "€#{c / 100}" : "€#{decimal(c)}" }
        low == high ? low : "#{low}–#{high}"
      end

      def menu_items(menus)
        Array(menus).flat_map { |m| Array(m.categories).flat_map { |c| category_items(c) } }
      end

      # Its items, leaving out any Nibble marks unavailable.
      def category_items(category)
        Array(category.items).reject { |i| i.available == false }
      end

      def business_schema
        b = nibble_business
        {
          "@type" => NibbleSite.options.establishment_type,
          "@id" => business_id,
          "name" => b.name,
          "legalName" => b.legal_name,
          "description" => site.metadata.description,
          "url" => "#{base_url}/",
          "telephone" => b.contact.phone,
          "email" => b.contact.email,
          "servesCuisine" => Array(b.cuisine),
          "priceRange" => price_range(site.data.nibble.menus),
          "address" => {"@type" => "PostalAddress", "addressLocality" => b.base.town, "addressRegion" => b.base.county, "addressCountry" => b.base.country},
          "areaServed" => area_served,
          "foundingDate" => b.founded.to_s,
          "logo" => "#{base_url}#{site.metadata.logo || "/images/brand/logo.png"}",
          "image" => "#{base_url}/images/share/#{site.metadata.share_image}.jpg",
          "sameAs" => [b.social.instagram, b.social.facebook].compact,
          "hasMenu" => "#{base_url}/menu/",
          "acceptsReservations" => false
        }.compact
      end

      def website_schema
        b = nibble_business
        {
          "@type" => "WebSite",
          "@id" => "#{base_url}/#website",
          "name" => b.name,
          "alternateName" => [b.legal_name].compact,
          "url" => "#{base_url}/",
          "inLanguage" => NibbleSite.options.language,
          "publisher" => {"@id" => business_id}
        }
      end

      # Home › page, or Home › Find us › location.
      def breadcrumbs_schema(resource, here)
        return nil if resource.relative_url == "/"

        trail = [["Home", "/"]]
        if here
          trail << ["Find us", "/locations/"]
          trail << [here.name, Places.path_for(here)]
        else
          return nil if Places.blank?(resource.data.title)

          trail << [resource.data.title, resource.relative_url]
        end
        {
          "@type" => "BreadcrumbList",
          "itemListElement" => trail.each_with_index.map do |(name, path), i|
            {"@type" => "ListItem", "position" => i + 1, "name" => name, "item" => "#{base_url}#{path}"}
          end
        }
      end

      def location_schema(here)
        b = nibble_business
        a = here.address
        page = "#{base_url}#{Places.path_for(here)}"
        weekly = Places.week_of(here).filter_map do |day, hours|
          next unless hours

          opens, closes = hours.split("–")
          {"@type" => "OpeningHoursSpecification", "dayOfWeek" => "https://schema.org/#{day.capitalize}", "opens" => opens, "closes" => closes}
        end
        # A closed day is "00:00" to "00:00", as Google asks.
        special = Places.special_dates(here).map do |date, _label, hours|
          opens, closes = hours ? hours.split("–") : %w[00:00 00:00]
          {"@type" => "OpeningHoursSpecification", "validFrom" => date.iso8601, "validThrough" => date.iso8601, "opens" => opens, "closes" => closes}
        end
        {
          "@type" => NibbleSite.options.establishment_type,
          "@id" => "#{page}#location",
          "name" => "#{b.name} at #{here.name}",
          "description" => here.description,
          "url" => page,
          "image" => (here.photo ? "#{base_url}/images/share/#{here.photo}.jpg" : here.photo_url),
          "servesCuisine" => Array(b.cuisine),
          "priceRange" => price_range(Places.menus_for(here, site.data.nibble.menus)),
          "telephone" => here.phone || b.contact.phone,
          "address" => {
            "@type" => "PostalAddress",
            "streetAddress" => [a.line1, a.line2].reject { Places.blank?(_1) }.join(", "),
            "addressLocality" => Places.blank?(a.city) ? a.line2 : a.city,
            "addressRegion" => a.county,
            "postalCode" => a.postcode,
            "addressCountry" => Places.blank?(a.country) ? "IE" : a.country
          }.reject { |_k, v| Places.blank?(v) },
          "geo" => (here.latitude && here.longitude ? {"@type" => "GeoCoordinates", "latitude" => here.latitude, "longitude" => here.longitude} : nil),
          "openingHoursSpecification" => weekly,
          "specialOpeningHoursSpecification" => (special.empty? ? nil : special),
          "hasMenu" => page,
          "potentialAction" => (here.order_ahead ? order_action(order_url_for(here)) : nil),
          "parentOrganization" => {"@id" => business_id}
        }.compact
      end

      def order_action(url)
        {
          "@type" => "OrderAction",
          "target" => {
            "@type" => "EntryPoint",
            "urlTemplate" => url,
            "actionPlatform" => ["https://schema.org/DesktopWebPlatform", "https://schema.org/MobileWebPlatform"]
          },
          "deliveryMethod" => "http://purl.org/goodrelations/v1#DeliveryModePickUp"
        }
      end

      # An event page (weddings, parties...) as a catering service, with its
      # packages as offers.
      def service_schema(resource)
        d = resource.data
        page = "#{base_url}#{resource.relative_url}"
        packages = Array(site.data.nibble.packages).select { |p| Array(p.kind).include?(d.kind) }
        {
          "@type" => "Service",
          "@id" => "#{page}#service",
          "name" => d.title,
          "serviceType" => "Catering",
          "description" => d.description,
          "url" => page,
          "provider" => {"@id" => business_id},
          "areaServed" => area_served,
          "hasOfferCatalog" => (packages.empty? ? nil : {
            "@type" => "OfferCatalog",
            "name" => "Packages",
            "itemListElement" => packages.map { |p| package_offer(p, page) }
          })
        }.compact
      end

      def package_offer(package, page)
        price = package.from_price_cents && decimal(package.from_price_cents)
        {
          "@type" => "Offer",
          "name" => package.name,
          "description" => package.summary,
          "url" => "#{page}#packages",
          "price" => price,
          "priceCurrency" => (price ? "EUR" : nil),
          "priceSpecification" => (price ? {"@type" => "PriceSpecification", "minPrice" => price, "priceCurrency" => "EUR"} : nil),
          "eligibleQuantity" => (package.guests_up_to ? {"@type" => "QuantitativeValue", "maxValue" => package.guests_up_to, "unitText" => "guests"} : nil)
        }.compact
      end

      def faq_schema(faqs)
        {
          "@type" => "FAQPage",
          "mainEntity" => Array(faqs).map do |faq|
            {"@type" => "Question", "name" => faq.q, "acceptedAnswer" => {"@type" => "Answer", "text" => faq.a}}
          end
        }
      end

      def menu_schema
        {
          "@type" => "Menu",
          "@id" => "#{base_url}/menu/#menu",
          "name" => "#{nibble_business.name} menu",
          "url" => "#{base_url}/menu/",
          "inLanguage" => NibbleSite.options.language,
          "hasMenuSection" => Array(site.data.nibble.menus).map do |menu|
            {
              "@type" => "MenuSection",
              "name" => menu.name,
              "description" => menu.description,
              "hasMenuSection" => Array(menu.categories).map do |category|
                {
                  "@type" => "MenuSection",
                  "name" => category.name,
                  "description" => category.description,
                  "hasMenuItem" => category_items(category).map do |item|
                    {
                      "@type" => "MenuItem",
                      "name" => item.name,
                      "description" => item.description,
                      "offers" => (item.price_cents ? {"@type" => "Offer", "price" => decimal(item.price_cents), "priceCurrency" => "EUR"} : nil)
                    }.compact
                  end
                }.compact
              end
            }.compact
          end
        }
      end

      # Each upcoming festival date. The business trades at these; it doesn't
      # run them, so they carry no organiser.
      def festival_schemas
        upcoming.reject(&:sample).map do |a|
          {
            "@type" => "Event",
            "name" => "#{nibble_business.name} at #{a.name}",
            "description" => a.note,
            "startDate" => a.starts_on.iso8601,
            "endDate" => (a.ends_on || a.starts_on).iso8601,
            "eventAttendanceMode" => "https://schema.org/OfflineEventAttendanceMode",
            "eventStatus" => "https://schema.org/EventScheduled",
            "location" => {
              "@type" => "Place",
              "name" => a.name,
              "address" => {"@type" => "PostalAddress", "addressLocality" => a.town, "addressRegion" => a.county, "addressCountry" => "IE"}.compact
            },
            "url" => a.url || "#{base_url}/festivals/"
          }.compact
        end
      end
  end
end
