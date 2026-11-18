require "test_helper"
require "bridgetown"
require "nibble_site/core"

class PlacesTest < Minitest::Test
  P = NibbleSite::Places

  def location(**fields)
    HashWithDotAccess::Hash.new({address: {}, opening_hours: {}}.merge(fields))
  end

  def test_county_names
    assert_equal "Co. Wicklow", P.county_name("CO WICKLOW")
    assert_equal "Co. Wicklow", P.county_name("co. wicklow")
    assert_equal "Co. Wicklow", P.county_name("County Wicklow")
    assert_equal "Co. Wicklow", P.county_name("Wicklow")
    assert_nil P.county_name(nil)
  end

  def test_place_is_the_town_before_the_second_line
    assert_equal "Kilcoole, Co. Wicklow", P.place_of(location(address: {line1: "Car park", line2: "Sea Road", city: "Kilcoole", county: "Co. Wicklow"}))
    assert_equal "Glen of the Downs, Co. Wicklow", P.place_of(location(address: {line1: "Market", line2: "Glen of the Downs", city: nil, county: "Co. Wicklow"}))
  end

  def test_findable_needs_an_address_or_hours
    refute P.findable?(location(address: {line1: nil, city: nil}))
    assert P.findable?(location(address: {city: "Bray"}))
    assert P.findable?(location(opening_hours: {"friday" => {"open" => "1", "from" => "17:00", "to" => "21:00"}}))
  end

  def test_hours_summary_groups_days
    hours = %w[friday saturday].to_h { [_1, {"open" => "1", "from" => "17:00", "to" => "21:30"}] }
    hours["sunday"] = {"open" => "1", "from" => "12:00", "to" => "18:00"}
    assert_equal "Fri–Sat 17:00–21:30 · Sun 12:00–18:00", P.summary_of(location(opening_hours: hours))
  end

  def test_special_dates_skip_the_past
    l = location(special_hours: {"2000-01-01" => {"closed" => true}, "2099-12-25" => {"closed" => true, "label" => "Christmas"}})
    assert_equal [[Date.new(2099, 12, 25), "Christmas", nil]], P.special_dates(l)
  end

  def test_euro
    assert_equal "€12", P.euro(1200)
    assert_equal "€2.50", P.euro(250)
    assert_equal "from €2,520", P.euro(252000, from: true)
  end
end
