# nibble_site

The shared engine behind Nibble's bespoke websites for food businesses: a
Bridgetown 2 plugin.

Each business has its own small site repository, with its own design, words
and photos. The engine is what every site does the same way: reading the
business's locations and menus from Nibble, making a page for each location,
and the search, sharing and AI parts. Fix something here, release a version,
and each site picks it up by bumping one line.

## What's in the engine, and what stays in a site

| The engine | Each site |
|---|---|
| Reading locations and menus from the Nibble API at build time | `src/_data/nibble/business.yml`, `packages.yml`, `appearances.yml`, and local stand-ins for locations and menus |
| A page for each location (`/locations/<slug>/`) | The `location` layout those pages use, and every other layout and partial |
| Leaving out sample data on the live site, and locations with no address and no hours | Its pages, words and photos |
| The helpers the templates use (below) | Colours, fonts, logo, icons, styles (Tailwind) |
| The `<head>` tags for search and sharing, and structured data for every page | Its JavaScript (Stimulus controllers) |
| `sitemap.xml`, `robots.txt`, `llms.txt` | `src/_data/redirects.yml`, its old website's addresses |
| Rack middleware: `/up`, `/reviews.json`, old-site redirects, the canonical domain, headers | Its `config.ru`, which turns them on |
| `nibble-site optimize-images`, `share-images`, `google-place-id` | |

Everything a visitor sees stays in the site, so every site can look
different. Bridgetown lets a plugin bring its own builders, layouts,
components and pages, but not partials; the visual parts are partials, and
belong to each design anyway.

## Using it in a site

**Gemfile**

```ruby
gem "bridgetown", "~> 2.1.2"
gem "nibble_site", git: "https://github.com/johnchambers/nibble-site.git", tag: "v0.1.0"
# samovar >= 2.4.2 dropped the mapping/model base class that bridgetown-core 2.1.2 patches at load
gem "samovar", "= 2.4.1"
```

**config/initializers.rb**

```ruby
Bridgetown.configure do |config|
  url ENV.fetch("SITE_URL", "https://www.theirbusiness.ie").strip.delete_suffix("/")
  template_engine "erb"
  timezone "Europe/Dublin"
  permalink "pretty"

  init :nibble_site, location_title: "Pizza at %{name}"
end
```

| Option | Default | What it is |
|---|---|---|
| `location_title` | `"%{name}"` | Each location page's title; `%{name}`, `%{place}`, `%{business}` |
| `location_description` | `"%{business} at %{name}, %{place}. Opening hours, the menu, directions, and order ahead online."` | Its description for search results, cut at 160 characters |
| `establishment_type` | `"FoodEstablishment"` | The schema.org type of the business and its locations |
| `language` | `"en-IE"` | For structured data |
| `og_locale` | `"en_IE"` | For sharing tags |

The engine sets `site_live` from `SITE_LIVE`; the site doesn't.

**config.ru**

```ruby
require "bridgetown-core/rack/boot"

Bridgetown::Rack.boot

use NibbleSite::Rack::CanonicalHost # other hostnames 301 to SITE_CANONICAL_HOST (when set)
use NibbleSite::Rack::StaticHeaders # HEAD support, cache and security headers
use NibbleSite::Rack::Endpoints     # /up, /reviews.json, the old site's addresses

run RodaApp.freeze.app
```

**The head.** In the site's `_head` partial (or layout):

```erb
<%= nibble_head_tags(resource) %>
```

That's the title, description, canonical link, robots, Open Graph and X
cards, and the structured data. Add the site's own icons, theme colour,
fonts, styles and scripts around it.

**A `location` layout** (`src/_layouts/location.erb`). Each location page
has `location_slug` in its data; find it with
`locations.find { |l| l.slug == resource.data.location_slug }`.

**Don't** add `sitemap.xml`, `robots.txt` or `llms.txt` to the site: the
engine makes them.

`example/` is a complete, plain site on the engine: copy what you need.

## The data

In `src/_data/nibble/`, shaped as the Nibble API answers:

| File | Notes |
|---|---|
| `business.yml` | `slug` (their Nibble slug), `name`, `legal_name`, `founded`, `tagline`, `cuisine`, `base` (town, county, country), `areas_served`, `contact` (phone, whatsapp, email), `social` (network: link), `google_reviews` (count, rating, url), `order_url` (leave empty for the Nibble storefront) |
| `locations.yml` | Used until `NIBBLE_API_URL` is set; then the API's answer replaces it |
| `menus.yml` | The same |
| `packages.yml` | Event packages: `name`, `kind` (a list), `from_price_cents`, `guests_up_to`, `summary`... |
| `appearances.yml` | Festival dates: `name`, `town`, `county`, `starts_on`, `ends_on`, `note`, `url` |

Anything marked `sample: true` in locations or appearances is shown on a
preview and left out of the live build.

In `src/_data/`: `site_metadata.yml` (`title`, `description`,
`share_image`, `share_alt`, and `logo`, the logo's path for structured
data, default `/images/brand/logo.png`) and `redirects.yml` (see
`lib/nibble_site/rack/endpoints.rb`).

## Front matter the engine reads

| Key | Effect |
|---|---|
| `title`, `full_title`, `description` | The page's title and description (`full_title` is used as it is) |
| `share_image` | A photo in `src/images/site`; `nibble-site share-images` makes its 1200×630 JPEG |
| `noindex: true` | Keeps one page out of search |
| `sitemap: false` | Leaves it out of the sitemap |
| `kind: wedding` | A service page: its structured data lists the packages of that kind, and `llms.txt` lists it under "Book us" |
| `faqs: [{q, a}]` | FAQ structured data |
| `menu_schema: true` | The menu page: the whole menu as structured data |
| `events_schema: true` | The festivals page: each upcoming date as an event |

## Helpers

| Helper | Gives |
|---|---|
| `nibble_head_tags(resource)` | The search and sharing tags |
| `structured_data(resource)` | The schema.org objects, if a site wants them alone |
| `locations` | The locations to show |
| `location_path(l)`, `location_place(l)`, `location_address_lines(l)`, `location_maps_url(l)` | Where it is: "/locations/x/", "Kilcoole, Co. Wicklow", its lines, directions |
| `location_order_url(l)`, `order_online_url` | Its ordering page; the business's |
| `location_menus(l)`, `menu_locations(menu)` | Its menus; where a menu is served |
| `weekly_hours(l)`, `hours_summary(l)`, `upcoming_special_hours(l)` | `[[day, "11:00–17:00" or nil]]`; "Sat 11:00–17:00 · Sun 12:30–18:30"; upcoming date changes |
| `upcoming_appearances`, `appearance_dates(a)` | Festival dates, soonest first; "5–6 June 2027" |
| `packages_for(kind)` | Packages of a kind |
| `euro(cents, from: false)` | "€12", "€2.50", "from €520" |
| `areas_sentence` | "Wicklow, Wexford and South Dublin" |
| `whatsapp_url(text = nil)` | A WhatsApp link to the business |
| `nav_children(item)` | A navigation.yml item's children, with every location first when it says `with_locations` |

## Environment variables

| Variable | Read | What it does |
|---|---|---|
| `SITE_URL` | At build (the site's initializer) | The site's address |
| `SITE_LIVE` | At build | `1` on the live site: search engines in, samples out |
| `NIBBLE_API_URL` | At build | Read locations and menus from Nibble (`https://nibble.ie`). A failed call stops the build |
| `NIBBLE_BUSINESS` | At build | The business's slug, if not `business.yml`'s |
| `SITE_CANONICAL_HOST` | While running | Send other hostnames here |
| `GOOGLE_PLACES_API_KEY`, `GOOGLE_PLACE_ID` | While running | The live Google review count for `/reviews.json` |

## Commands

Run from a site's folder:

```sh
bundle exec nibble-site optimize-images   # WebP variants and src/_data/images.yml (needs cwebp, sips)
bundle exec nibble-site share-images      # 1200×630 sharing JPEGs in src/images/share (needs sips)
GOOGLE_PLACES_API_KEY=... bundle exec nibble-site google-place-id "Name Town"
```

## Working on the engine

```sh
bundle install
bundle exec rake test        # unit tests, and builds of example/ as a preview, live, and against a stand-in Nibble API
cd example && bundle install && bundle exec bridgetown build   # look at the output
```

To try the example against real data:

```sh
cd example
NIBBLE_API_URL=https://nibble.ie NIBBLE_BUSINESS=<slug> bundle exec bridgetown build
```

**Releasing:** change `lib/nibble_site/version.rb` and `CHANGELOG.md`, merge,
then tag `vX.Y.Z` on main and push the tag. Each site moves to it by
changing the `tag:` in its Gemfile, `bundle update nibble_site`, and a pull
request. Anything that needs a site to change (a renamed helper, a new
required file) is a new minor version, with the change spelt out in the
changelog.
