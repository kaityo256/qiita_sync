# coding: utf-8
require 'yaml'
require 'open-uri'
DIRLIST = "dirlist.yaml"

data = YAML.load(File.open("qiita.yaml"))


def qiita2gh(body, dir)
  str = ""
  image_files = 0
  in_math = false
  body.split(/\R/) do |line|
    if in_math
      if line=~/```/
        str = str + "$$\n"
        in_math = false
      elsif line=~/\\begin{align}/
        str = str + "\\begin{aligned}\n"
      elsif line=~/\\end{align}/
        str = str + "\\end{aligned}\n"
      else
        str = str + line + "\n"
      end
      next
    end
    if line=~/```math/
      in_math = true
      str = str + "$$\n"
      next
    end

    if line =~/^#+(\s+.*)/
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
    elsif line=~/```(.*):.*/
      line = "```" + $1
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

dirlist = nil

# ディレクトリとの対応表
if File.exist?(DIRLIST)
  # あれば読み込む
  puts "Found #{DIRLIST}."
  dirlist = YAML.load(File.open(DIRLIST))
  # 欠落をチェック
  data.each do |d|
    title = d["title"]
    if !dirlist.has_key?(title)
      puts "New article: #{title}"
      dirlist[title] = nil
    end
  end
  YAML.dump(dirlist, File.open(DIRLIST, "w"))
else
  # なければ作る
  dirlist = {}
  data.each do |d|
    title = d["title"]
    dirlist[title] = nil
  end
  YAML.dump(dirlist, File.open(DIRLIST, "w"))
  puts "#{DIRLIST} is not found. Created it."
end

def sync(data, dirlist)
  data.each do |article|
    title = article["title"]
    if dirlist[title]
      dir = dirlist[title]
      dump_data(article, dir)
    end
  end
end

sync(data, dirlist)