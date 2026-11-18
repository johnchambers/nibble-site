require "minitest/autorun"
require "json"
require "socket"
require "tmpdir"
require "open3"

EXAMPLE = File.expand_path("../example", __dir__)

module SiteBuild
  # Builds the example site into a fresh folder with the given environment,
  # and returns [folder, log, success].
  def build_example(env = {})
    dir = Dir.mktmpdir("nibble-site-test")
    env = {"BUNDLE_GEMFILE" => File.join(EXAMPLE, "Gemfile"), "SITE_LIVE" => nil, "NIBBLE_API_URL" => nil, "NIBBLE_BUSINESS" => nil}.merge(env)
    log, status = Open3.capture2e(env, "bundle", "exec", "bridgetown", "build", "--destination", dir, chdir: EXAMPLE)
    [dir, log, status.success?]
  end

  def schema_types(html)
    html.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).map { JSON.parse(_1.first)["@type"] }
  end

  def read(dir, path)
    File.read(File.join(dir, path))
  end
end

# A stand-in for the Nibble API: answers each path from a hash, 404 otherwise.
class FakeNibble
  attr_reader :url

  def initialize(routes)
    @server = TCPServer.new("127.0.0.1", 0)
    @url = "http://127.0.0.1:#{@server.addr[1]}"
    @thread = Thread.new do
      loop do
        client = @server.accept
        path = client.gets.to_s.split[1]
        nil until client.gets.to_s.strip.empty?
        body = routes[path]
        client.write(body ? "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}" : "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
        client.close
      end
    rescue IOError
      nil
    end
  end

  def stop
    @server.close
    @thread.kill
  end
end
