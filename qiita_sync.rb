# coding: utf-8
require 'json'
require 'yaml'
require "fileutils"
require 'net/http'

$ACCESS_TOKEN = ENV['QIITA_TOKEN']
if $ACCESS_TOKEN == nil
    puts "Environment QIITA_TOKEN is not defined."
    exit(-1)
end

$GET_ITEMS_URI = 'https://qiita.com/api/v2/items'
$PER_PAGE = 100
$USER = "kaityo256"

def get_page(page, data)
    query = "user:#{$USER}"
    uri = URI.parse($GET_ITEMS_URI)
    uri.query = URI.encode_www_form({ query: query, per_page: $PER_PAGE, page: page })
    req = Net::HTTP::Get.new(uri.request_uri)
    req['Authorization'] = "Bearer #{$ACCESS_TOKEN}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    res = http.request(req)
    total_page = ((res['total-count'].to_i - 1) / $PER_PAGE) + 1
    items = JSON.parse(res.body)
    items.each do |item|
        h = {}
        h["title"] = item["title"]
        h["url"] = item["url"]
        h["body"] = item["body"]
        data.push h
      end
    return page < total_page
end

def get_all
    data = []
    page = 1
    while get_page(page, data)
        page = page + 1
    end
    data
end

data = get_all
YAML.dump(data, File.open("qiita.yaml","w"))