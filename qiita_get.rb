require "json"
require "yaml"
require "fileutils"
require "net/http"

# Qiitaの全データを取得するスクリプト

$QIITA_USER = ENV["QIITA_USER"]

if $QIITA_USER.nil?
  puts "Environment QIITA_USER is not defined."
  exit(-1)
end

$QIITA_TOKEN = ENV["QIITA_TOKEN"]
if $QIITA_TOKEN.nil?
  puts "Environment QIITA_TOKEN is not defined."
  exit(-1)
end

$GET_ITEMS_URI = "https://qiita.com/api/v2/items"
$PER_PAGE = 100

def get_page(page, data)
  query = "user:#{$QIITA_USER}"
  uri = URI.parse($GET_ITEMS_URI)
  uri.query = URI.encode_www_form({query: query, per_page: $PER_PAGE, page: page})
  req = Net::HTTP::Get.new(uri.request_uri)
  req["Authorization"] = "Bearer #{$QIITA_TOKEN}"

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  res = http.request(req)
  total_pages = ((res["total-count"].to_i - 1) / $PER_PAGE) + 1
  puts "Page = #{page}/#{total_pages}"
  items = JSON.parse(res.body)
  jsonfile = "qiita#{page}.json"
  JSON.dump(items, File.open(jsonfile, "w"))
  items.each do |item|
    h = {}
    h["title"] = item["title"]
    h["url"] = item["url"]
    h["body"] = item["body"]
    h["updated_at"] = item["updated_at"]
    puts h["title"]
    data.push h
  end
  page < total_pages
end

def get_all
  data = []
  page = 1
  page += 1 while get_page(page, data)
  data
end

data = get_all
YAML.dump(data, File.open("qiita.yaml", "w"))
