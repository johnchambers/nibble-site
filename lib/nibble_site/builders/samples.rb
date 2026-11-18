module NibbleSite
  module Builders
    # Sample data (anything in src/_data/nibble marked `sample: true`) shows
    # how the pages look before the business's real details are in, and the
    # pages label it. On the live site (SITE_LIVE=1) it's dropped when the
    # site is built, so a made-up location or festival date never reaches
    # Google, the sitemap or a customer, even if nobody remembers to delete
    # it. Data from the Nibble API has no samples.
    class Samples < Bridgetown::Builder
      def build
        hook :site, :post_read do |site|
          next unless site.config.site_live

          nibble = site.data.nibble
          %i[locations appearances].each do |key|
            next unless nibble[key]

            real = Array(nibble[key]).reject { |item| item["sample"] }
            dropped = Array(nibble[key]).size - real.size
            nibble[key] = real
            Bridgetown.logger.info "Samples:", "left out #{dropped} sample #{key} on the live site" if dropped.positive?
          end
        end
      end
    end
  end
end
