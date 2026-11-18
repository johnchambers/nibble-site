module NibbleSite
  module Builders
    # Reads the business's locations and menus from the Nibble API when the
    # site is built, in place of src/_data/nibble/locations.yml and
    # menus.yml.
    #
    #   NIBBLE_API_URL=https://nibble.ie        where Nibble is
    #   NIBBLE_BUSINESS=<slug>                  the business's slug in Nibble
    #                                           (default: business.yml `slug`)
    #
    # Without NIBBLE_API_URL the YAML files are used, sample data and all,
    # which is what a local build and a preview do until the business is set
    # up in Nibble. With it, a failed call stops the build, so a live site
    # never falls back to sample data; Hatchbox keeps the last good release.
    #
    # The API: nibble/app/controllers/api/v1/businesses_controller.rb.
    class Data < Bridgetown::Builder
      def build
        base = ENV.fetch("NIBBLE_API_URL", "").strip.delete_suffix("/")
        return if base.empty?

        hook :site, :post_read do |site|
          api = "#{base}/api/v1/businesses/#{NibbleSite::Builders::Data.slug(site)}"
          locations = fetch("#{api}/locations")["locations"]
          menus = fetch("#{api}/menus")["menus"]
          site.data.nibble[:locations] = locations
          site.data.nibble[:menus] = menus
          Bridgetown.logger.info "Nibble:", "#{locations.size} locations and #{menus.size} menus from #{api}"
        end
      end

      # The business's slug in Nibble: NIBBLE_BUSINESS, or business.yml.
      def self.slug(site)
        slug = ENV.fetch("NIBBLE_BUSINESS", "").strip
        slug.empty? ? site.data.nibble.business.slug.to_s : slug
      end

      private

      def fetch(url)
        uri = URI(url)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 20) do |http|
          http.get(uri.request_uri, "Accept" => "application/json")
        end
        raise "Nibble API #{url} answered #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      end
    end
  end
end
