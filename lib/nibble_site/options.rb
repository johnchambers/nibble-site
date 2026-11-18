module NibbleSite
  # What a site can set when it turns the engine on:
  #
  #   init :nibble_site,
  #     location_title: "Pizza at %{name}",
  #     location_description: "%{business}'s stone-baked pizza at %{name}, %{place}. ..."
  #
  # location_title        each location page's title (" | <site name>" is
  #                       added by the head); %{name}, %{place}, %{business}
  # location_description  its description for search results, cut at 160
  #                       characters; the same placeholders
  # establishment_type    schema.org type of the business and its locations
  # language              the pages' language, for structured data and llms.txt
  # og_locale             the language for sharing tags
  Options = Struct.new(:location_title, :location_description, :establishment_type, :language, :og_locale, keyword_init: true) do
    def initialize(location_title: "%{name}",
      location_description: "%{business} at %{name}, %{place}. Opening hours, the menu, directions, and order ahead online.",
      establishment_type: "FoodEstablishment", language: "en-IE", og_locale: "en_IE")
      super
    end
  end

  class << self
    attr_writer :options

    def options
      @options ||= Options.new
    end
  end
end
