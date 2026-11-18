require "bridgetown-core/rack/boot"

Bridgetown::Rack.boot

use NibbleSite::Rack::CanonicalHost # other hostnames 301 to SITE_CANONICAL_HOST (when set)
use NibbleSite::Rack::StaticHeaders # HEAD support, cache and security headers
use NibbleSite::Rack::Endpoints     # /up, /reviews.json, the old site's addresses

run RodaApp.freeze.app
