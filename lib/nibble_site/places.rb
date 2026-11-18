module NibbleSite
  # Working with a location as Nibble sends it (an Outlet, through
  # GET /api/v1/businesses/:slug/locations): its address, hours and menus.
  # Plain functions of the data, used by the builders and the helpers.
  module Places
    DAYS = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

    module_function

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end

    def path_for(location)
      "/locations/#{location.slug}/"
    end

    # "Kilcoole, Co. Wicklow": the town, or the second address line when
    # there's no town.
    def place_of(location)
      a = location.address
      return "" unless a

      [blank?(a.city) ? a.line2 : a.city, a.county].reject { blank?(_1) }.uniq.join(", ")
    end

    def address_lines(location)
      a = location.address
      return [] unless a

      [a.line1, a.line2, [a.city, a.postcode].reject { blank?(_1) }.join(" "), a.county].reject { blank?(_1) }
    end

    # Directions in Google Maps: by map position when it has one.
    def maps_url(location)
      query = if location.latitude && location.longitude
        "#{location.latitude},#{location.longitude}"
      else
        ([location.name] + address_lines(location)).uniq.join(", ")
      end
      "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(query)}"
    end

    # Its menus: its own, or every menu when it has none (Outlet#till_menus).
    def menus_for(location, menus)
      all = Array(menus)
      chosen = Array(location.menus).map(&:to_s)
      chosen.empty? ? all : all.select { |m| chosen.include?(m.id.to_s) }
    end

    # Each day of the week: [day, "11:00–17:00" or nil when closed].
    def week_of(location)
      DAYS.map do |day|
        h = location.opening_hours&.dig(day)
        open = h && h["open"].to_s == "1" && !blank?(h["from"]) && !blank?(h["to"])
        [day, open ? "#{h["from"]}–#{h["to"]}" : nil]
      end
    end

    # "Fri–Sat 17:00–21:30" / "Sat 11:00–17:00 · Sun 12:30–18:30"
    def summary_of(location)
      week_of(location).chunk_while { |a, b| a[1] == b[1] }.filter_map do |run|
        next unless run.first[1]

        first, last = run.first[0][0, 3].capitalize, run.last[0][0, 3].capitalize
        "#{run.size > 1 ? "#{first}–#{last}" : first} #{run.first[1]}"
      end.join(" · ")
    end

    # Upcoming date changes, soonest first: [[Date, label, hours or nil]].
    def special_dates(location, today = Date.today)
      (location.special_hours || {}).filter_map do |date, h|
        d = Date.parse(date.to_s)
        next if d < today

        [d, h["label"], h["closed"] ? nil : "#{h["from"]}–#{h["to"]}"]
      end.sort_by(&:first)
    end

    # Somewhere a customer can go: an address or opening hours. A location
    # with neither (an events truck) has nothing to show on a "Find us" card.
    def findable?(location)
      a = location.address
      has_address = a && [a.line1, a.line2, a.city].any? { !blank?(_1) }
      has_hours = (location.opening_hours || {}).values.any? { |h| h["open"].to_s == "1" }
      !!(has_address || has_hours)
    end

    # "Co. Wicklow", however it was typed ("CO WICKLOW", "co wicklow",
    # "County Wicklow", "Wicklow").
    def county_name(county)
      name = county.to_s.strip.sub(/\Aco(unty)?\.?\s+/i, "")
      return county if name.empty?

      "Co. #{name.split(/\s+/).map(&:capitalize).join(" ")}"
    end

    # "€12", "€2.50", "from €520"
    def euro(cents, from: false)
      return "" if cents.nil?

      amount = (cents % 100 == 0) ? (cents / 100).to_s.reverse.scan(/\d{1,3}/).join(",").reverse : format("%.2f", cents / 100.0)
      "#{"from " if from}€#{amount}"
    end
  end
end
