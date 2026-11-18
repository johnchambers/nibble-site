require_relative "lib/nibble_site/version"

Gem::Specification.new do |spec|
  spec.name = "nibble_site"
  spec.version = NibbleSite::VERSION
  spec.authors = ["John Chambers"]
  spec.summary = "The shared engine behind Nibble's bespoke websites for food businesses"
  spec.description = "A Bridgetown plugin: reads a business's locations and menus from the Nibble API, " \
                     "makes a page for each location, and adds the search, sharing and AI parts every site needs."
  spec.homepage = "https://github.com/johnchambers/nibble-site"
  spec.license = "Nonstandard"
  spec.required_ruby_version = ">= 3.4"

  spec.files = Dir["lib/**/*", "content/**/*", "exe/*", "README.md", "CHANGELOG.md"]
  spec.bindir = "exe"
  spec.executables = ["nibble-site"]
  spec.require_paths = ["lib"]

  spec.add_dependency "bridgetown", "~> 2.1"
  spec.add_dependency "rack", ">= 3"
end
