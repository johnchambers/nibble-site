require "test_helper"
require "rack/test"
require "bridgetown"
require "nibble_site/core"

class EndpointsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    inner = ->(_env) { [200, {"content-type" => "text/html"}, ["page"]] }
    NibbleSite::Rack::Endpoints.new(inner, redirects: File.join(EXAMPLE, "src/_data/redirects.yml"))
  end

  def test_health_check
    get "/up"
    assert_equal "OK", last_response.body
  end

  def test_reviews_without_google_settings
    ENV.delete("GOOGLE_PLACES_API_KEY")
    get "/reviews.json"
    assert_equal 204, last_response.status
  end

  def test_old_addresses_redirect
    get "/page/about-us/"
    assert_equal 301, last_response.status
    assert_equal "/", last_response.headers["location"]
    get "/product/anything-at-all"
    assert_equal "/menu/", last_response.headers["location"]
  end

  def test_other_addresses_pass_through
    get "/menu/"
    assert_equal "page", last_response.body
  end
end

class CanonicalHostTest < Minitest::Test
  include Rack::Test::Methods

  def app
    ENV["SITE_CANONICAL_HOST"] = "www.examplepizza.ie"
    NibbleSite::Rack::CanonicalHost.new(->(_env) { [200, {}, ["page"]] })
  ensure
    ENV.delete("SITE_CANONICAL_HOST")
  end

  def test_other_hosts_go_to_the_canonical_one
    get "http://examplepizza.ie/menu/?a=1"
    assert_equal 301, last_response.status
    assert_equal "https://www.examplepizza.ie/menu/?a=1", last_response.headers["location"]
  end

  def test_health_check_is_exempt
    get "http://examplepizza.ie/up"
    assert_equal 200, last_response.status
  end
end
