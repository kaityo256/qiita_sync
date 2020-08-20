# coding: utf-8
require 'yaml'
require 'open-uri'

data = YAML.load(File.open("qiita.yaml"))
dirlist = YAML.load(File.open("dirlist.yaml"))

def qiita2gh(body, dir)
  str = ""
  image_files = 0
  body.split(/\R/) do |line|
    if line =~/#(.*)/
      line = "##" + $1
    elsif line=~/.*(https:\/\/qiita-image-store.*)\)/
      url = $1
      ext = File.extname(url)
      puts url, ext
      local_file = "image#{image_files}#{ext}"
      image_file = dir + "/" + local_file
      image_files +=1
      open(image_file, 'w') do |f|
        URI.open(url) do |img|
          puts "Download from #{url} to #{image_file}"
         f.write(img.read)
        end
      end
      line = "![#{local_file}](#{local_file})"
    end
    str = str + line + "\n"
  end
  str
end

def latest?(article, dir)
  if !File.directory?(dir)
    puts "Create direcotry #{dir}"
    Dir.mkdir(dir)
    return false
  end
  filename = dir + "/README.md"
  file_date = File::Stat.new(filename).mtime
  article_date = Time.iso8601(article["updated_at"])
  return file_date > article_date
end

def dump_data(article, dir)
  return if latest?(article, dir)
  filename = dir + "/README.md"
  open(filename, "w") do |f|
    f.puts "# #{article["title"]}"
    f.puts 
    body = qiita2gh(article["body"], dir)
    f.puts body
  end
end


data.each do |d|
  title = d["title"]
  if dirlist.has_key?(title)
    dir = dirlist[title]
    dump_data(d, dir)
  end
end
