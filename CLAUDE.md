# nibble_site

The shared engine (a Bridgetown 2 plugin gem) behind Nibble's bespoke
websites for food businesses. Read `README.md` first: what's in the engine
and what stays in each site, every option, helper and setting.

## Commands

- `bundle exec rake test` — unit tests, and builds of `example/` (preview,
  live, and against a stand-in Nibble API). Run before every pull request.
- `cd example && bundle exec bridgetown build` — build the example site.

## Rules

- **Nothing about one business in here.** No names, prices, places or
  wording that belong to one site; anything that differs between sites is
  an option (`lib/nibble_site/options.rb`), data, or stays in the site.
- **Nothing a visitor sees.** Layouts, partials, styles and JavaScript stay
  in each site so every design is its own. The engine gives data, helpers
  and the non-visual output (head tags, structured data, sitemap...).
- **Every site depends on this.** Keep helpers' names and behaviour stable.
  A change a site has to act on is a new minor version, spelt out in
  `CHANGELOG.md`.
- **Test it in `example/`.** Add the case to `example/src/_data` and a test
  in `test/`.
- Plain Ruby in the builders: no ActiveSupport (`presence`, `blank?` as a
  method...). `Places.blank?` is there for that.
- Work on a branch and open a pull request; John merges and tags releases.
