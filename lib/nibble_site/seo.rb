module NibbleSite
  # The search and sharing tags for a page's <head>: title, description,
  # canonical link, robots, Open Graph and X cards, and the structured data.
  # A site's _head partial calls `nibble_head_tags(resource)` and adds its
  # own icons, fonts, styles and scripts around it.
  #
  # A page sets in its front matter:
  #   title         its name; " | <site name>" is added. Keep the whole
  #                 thing under about 60 characters.
  #   full_title    a whole title, used as it is (the home page).
  #   description   about 150 characters; search results cut it there.
  #   share_image   a photo in src/images/site, shown when the page is
  #                 shared; `nibble-site share-images` makes the 1200×630
  #                 JPEG in src/images/share.
  #   share_url     a picture elsewhere (a location's photo from Nibble),
  #                 used when there's no share_image.
  #   noindex       true to keep one page out of search.
  #
  # site_metadata.yml gives the site's name (`title`), the default
  # `description` and `share_image`, and `share_alt`, the default words for
  # the sharing picture.
  #
  # Included in Builders::Helpers, with StructuredData.
  module Seo
    private

    def head_tags(resource)
      meta = site.metadata
      d = resource.data
      pick = ->(*values) { values.find { |v| !Places.blank?(v) } }

      page_title = d.full_title || [d.title, meta.title].reject { Places.blank?(_1) }.join(" | ")
      description = pick.(d.description, meta.description)
      page_url = "#{site.config.url}#{resource.relative_url}".sub(%r{(?<!:)/{2,}}, "/")
      share_local = !Places.blank?(d.share_image) || Places.blank?(d.share_url)
      share_url = share_local ? "#{site.config.url}/images/share/#{pick.(d.share_image, meta.share_image)}.jpg" : d.share_url
      share_alt = "#{meta.title}: #{pick.(d.title, meta.share_alt, site.data.nibble.business&.tagline)}"

      tags = []
      tags << tag(:title, page_title)
      tags << meta_tag(:name, "description", description)
      tags << %(<link rel="canonical" href="#{h(page_url)}">)
      tags << meta_tag(:name, "robots", "noindex") if !site.config.site_live || d.noindex
      tags << ""
      {
        "og:type" => "website", "og:site_name" => meta.title, "og:locale" => NibbleSite.options.og_locale,
        "og:url" => page_url, "og:title" => page_title, "og:description" => description, "og:image" => share_url
      }.each { |property, value| tags << meta_tag(:property, property, value) }
      # Its size is known only for the pictures the site makes itself.
      if share_local
        tags << meta_tag(:property, "og:image:type", "image/jpeg")
        tags << meta_tag(:property, "og:image:width", "1200")
        tags << meta_tag(:property, "og:image:height", "630")
      end
      tags << meta_tag(:property, "og:image:alt", share_alt)
      {
        "twitter:card" => "summary_large_image", "twitter:title" => page_title, "twitter:description" => description,
        "twitter:image" => share_url, "twitter:image:alt" => share_alt
      }.each { |name, value| tags << meta_tag(:name, name, value) }
      tags << ""
      schema_for(resource).each do |graph|
        tags << %(<script type="application/ld+json">#{JSON.generate(graph).gsub("</", "<\\/")}</script>)
      end
      tags.join("\n").html_safe
    end

    def h(value)
      ERB::Util.html_escape(value.to_s)
    end

    def tag(name, text)
      "<#{name}>#{h(text)}</#{name}>"
    end

    def meta_tag(attribute, key, value)
      %(<meta #{attribute}="#{h(key)}" content="#{h(value)}">)
    end
  end
end
