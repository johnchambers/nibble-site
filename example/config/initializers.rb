Bridgetown.configure do |config|
  url ENV.fetch("SITE_URL", "https://www.examplepizza.ie").strip.delete_suffix("/")
  template_engine "erb"
  timezone "Europe/Dublin"
  permalink "pretty"

  init :nibble_site, location_title: "Pizza at %{name}"
end
