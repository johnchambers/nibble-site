require "test_helper"

# Builds the example site, as a preview, as the live site and against a
# stand-in Nibble API, and checks what comes out.
class BuildTest < Minitest::Test
  include SiteBuild

  def preview
    @@preview ||= build_example
  end

  def live
    @@live ||= build_example("SITE_LIVE" => "1")
  end

  def test_builds
    assert preview[2], preview[1]
    assert live[2], live[1]
  end

  def test_location_pages
    dir = preview[0]
    assert File.exist?(File.join(dir, "locations/bray-seafront/index.html"))
    page = read(dir, "locations/bray-seafront/index.html")
    assert_includes page, "<title>Pizza at Bray Seafront | Example Pizza</title>"
    assert_includes page, %(<p class="place">Bray, Co. Wicklow</p>)
    assert_includes page, "https://nibble.ie/example-pizza/at/bray-seafront"
    assert_equal %w[FoodEstablishment BreadcrumbList FoodEstablishment], schema_types(page)
  end

  def test_locations_with_nowhere_to_find_them_are_left_off
    refute File.exist?(File.join(preview[0], "locations/events-truck/index.html"))
    refute_includes read(preview[0], "index.html"), "Events Truck"
  end

  def test_samples_show_on_the_preview_only
    assert File.exist?(File.join(preview[0], "locations/greystones-harbour/index.html"))
    refute File.exist?(File.join(live[0], "locations/greystones-harbour/index.html"))
    refute_includes read(live[0], "sitemap.xml"), "greystones"
    refute_includes read(live[0], "festivals/index.html"), "Made-up Fest"
    refute_includes read(live[0], "llms.txt"), "Greystones"
  end

  def test_preview_is_hidden_from_search
    assert_includes read(preview[0], "index.html"), %(<meta name="robots" content="noindex">)
    assert_includes read(preview[0], "robots.txt"), "Disallow: /"
    refute_includes read(live[0], "index.html"), "noindex"
    assert_includes read(live[0], "robots.txt"), "Sitemap: https://www.examplepizza.ie/sitemap.xml"
  end

  def test_structured_data_by_page
    dir = live[0]
    assert_equal %w[FoodEstablishment WebSite], schema_types(read(dir, "index.html"))
    assert_equal %w[FoodEstablishment BreadcrumbList Service FAQPage], schema_types(read(dir, "weddings/index.html"))
    assert_equal %w[FoodEstablishment BreadcrumbList Menu], schema_types(read(dir, "menu/index.html"))
    assert_equal %w[FoodEstablishment BreadcrumbList Event], schema_types(read(dir, "festivals/index.html"))
    menu = read(dir, "menu/index.html")
    refute_includes menu, "Sold out special"
  end

  def test_llms_txt
    text = read(live[0], "llms.txt")
    assert_includes text, "# Example Pizza"
    assert_includes text, "- Wedding Pizza Party: from €950, for up to 80 guests."
    assert_includes text, "- [Home](https://www.examplepizza.ie/)"
    refute_includes text, "&amp;"
  end

  def test_reads_locations_and_menus_from_nibble
    location = {slug: "harbour", name: "The Harbour", description: "From Nibble", address: {line1: "Pier", city: "Howth", county: "CO DUBLIN", country: "IE"},
                opening_hours: {saturday: {open: "1", from: "12:00", to: "18:00"}}, special_hours: {}, menus: [7], order_ahead: true,
                order_url: "https://nibble.ie/real-pizza/at/harbour", photo_url: "https://nibble.ie/photo.jpg"}
    menu = {id: 7, name: "Nibble menu", categories: [{name: "Pizzas", items: [{name: "Nduja", price_cents: 1600}]}]}
    api = FakeNibble.new("/api/v1/businesses/real-pizza/locations" => JSON.generate(locations: [location]),
      "/api/v1/businesses/real-pizza/menus" => JSON.generate(currency: "EUR", menus: [menu]))
    dir, log, ok = build_example("NIBBLE_API_URL" => api.url, "NIBBLE_BUSINESS" => "real-pizza")
    assert ok, log
    page = read(dir, "locations/harbour/index.html")
    assert_includes page, "Howth, Co. Dublin"
    assert_includes page, "Nduja €16"
    assert_includes page, %(<meta property="og:image" content="https://nibble.ie/photo.jpg">)
    refute File.exist?(File.join(dir, "locations/bray-seafront/index.html"))
  ensure
    api&.stop
  end

  def test_a_failed_nibble_call_stops_the_build
    api = FakeNibble.new({})
    _dir, _log, ok = build_example("NIBBLE_API_URL" => api.url, "NIBBLE_BUSINESS" => "missing")
    refute ok
  ensure
    api&.stop
  end
end
