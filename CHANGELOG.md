# Changelog

## 0.1.0 (18 November 2026)

The first release, extracted from Nibble's first vendor website:

- Locations and menus from the Nibble API at build time (`NIBBLE_API_URL`,
  `NIBBLE_BUSINESS`); a failed call stops the build.
- A page for each location; samples left out on the live site; locations
  with no address and no hours left out; counties written "Co. Wicklow".
- Template helpers, `nibble_head_tags`, structured data for every page.
- `sitemap.xml`, `robots.txt`, `llms.txt`.
- Rack middleware: `/up`, `/reviews.json` (Google rating and review count),
  old-site redirects from `src/_data/redirects.yml`, the canonical domain,
  cache and security headers.
- `nibble-site optimize-images`, `share-images`, `google-place-id`.
- `site_metadata.yml` `logo` sets the logo in structured data.
- `llms.txt` lists online ordering only when the business takes it.
