require "json"
require "yaml"
require "fileutils"
require "net/http"

# Qiitaの全データを取得するスクリプト

class QiitaGetter
  PER_PAGE = 100
  ITEMS_URI = "https://qiita.com/api/v2/items".freeze

  def self.article(item)
    puts item["title"]
    h = {}
    h["title"] = item["title"]
    h["url"] = item["url"]
    h["body"] = item["body"]
    h["updated_at"] = item["updated_at"]
    h["created_at"] = item["created_at"]
    h
  end

  def self.grab_page(page, data, user, token)
    query = "user:#{user}"
    uri = URI.parse(ITEMS_URI)
    uri.query = URI.encode_www_form({query: query, per_page: PER_PAGE, page: page})
    req = Net::HTTP::Get.new(uri.request_uri)
    req["Authorization"] = "Bearer #{token}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    res = http.request(req)
    total_pages = ((res["total-count"].to_i - 1) / PER_PAGE) + 1
    puts "Page = #{page}/#{total_pages}"
    items = JSON.parse(res.body)
    JSON.dump(items, File.open("qiita#{page}.json", "w"))
    items.each do |item|
      data.push article(item)
    end
    page < total_pages
  end

  def self.grab(user, token)
    data = []
    page = 1
    page += 1 while grab_page(page, data, user, token)
    data
  end
end

qiita_user= ENV["QIITA_USER"]

if qiita_user.nil?
  puts "Environment QIITA_USER is not defined."
  exit(-1)
end

qiita_token = ENV["QIITA_TOKEN"]
if qiita_token.nil?
  puts "Environment QIITA_TOKEN is not defined."
  exit(-1)
end

data = QiitaGetter.grab(qiita_user, qiita_token)
YAML.dump(data, File.open("qiita.yaml", "w"))
