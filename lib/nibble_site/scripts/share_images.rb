# Run as `nibble-site share-images` from a site's folder.
# Makes the pictures shown when a page is shared (WhatsApp, Facebook,
# iMessage, LinkedIn, X): a 1200×630 JPEG for every photo a page names as
# `share_image:` in its front matter, each location's `photo`, and the
# site's default (`share_image` in src/_data/site_metadata.yml). They are cropped from the
# photos in src/images/site and written to src/images/share.
#
# JPEG, not WebP: several apps still don't show a WebP preview.
#
# Run it after changing a page's share_image, and commit the results.
# Needs macOS's `sips`.
require "yaml"
require "shellwords"

ROOT = Dir.pwd
SOURCE_DIR = File.join(ROOT, "src/images/site")
OUT_DIR = File.join(ROOT, "src/images/share")
W, H = 1200, 630

names = Dir[File.join(ROOT, "src/**/*.{erb,html,md}")].filter_map do |path|
  File.read(path)[/\A---\s*\n.*?^share_image:\s*(\S+)/m, 1]
end
names << YAML.load_file(File.join(ROOT, "src/_data/site_metadata.yml"))["share_image"]
# Each location's page shares its photo (plugins/builders/location_pages.rb).
locations_file = File.join(ROOT, "src/_data/nibble/locations.yml")
names += Array(YAML.load_file(locations_file)).map { _1["photo"] } if File.exist?(locations_file)
names = names.compact.uniq.sort

Dir.mkdir(OUT_DIR) unless Dir.exist?(OUT_DIR)
names.each do |name|
  source = Dir[File.join(SOURCE_DIR, "#{name}.{jpg,jpeg,png}")].first or abort "No photo #{name} in src/images/site"
  out = File.join(OUT_DIR, "#{name}.jpg")
  dims = `sips -g pixelWidth -g pixelHeight #{source.shellescape}`
  w, h = dims[/pixelWidth: (\d+)/, 1].to_f, dims[/pixelHeight: (\d+)/, 1].to_f
  # Scale so the photo covers 1200×630, then crop the middle.
  scale = [W / w, H / h].max
  system("sips", "-s", "format", "jpeg", "-s", "formatOptions", "80",
    "-z", (h * scale).ceil.to_s, (w * scale).ceil.to_s, source, "--out", out, out: File::NULL, exception: true)
  system("sips", "-c", H.to_s, W.to_s, out, out: File::NULL, exception: true)
  puts "share/#{name}.jpg  #{File.size(out) / 1024} KB#{"  (enlarged from #{w.to_i}px wide)" if scale > 1}"
end
