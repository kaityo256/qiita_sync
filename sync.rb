require "yaml"
require "open-uri"

def qiita2gh(body, dir)
  str = ""
  image_index = 0
  in_math = false
  body.split(/\R/).each do |line|
    if in_math
      if line =~ /```/
        str += "$$\n"
        in_math = false
      elsif line =~ /\\begin{align}/
        str += "\\begin{aligned}\n"
      elsif line =~ /\\end{align}/
        str += "\\end{aligned}\n"
      else
        str = str + line + "\n"
      end
      next
    end
    if line =~ /```math/
      in_math = true
      str += "$$\n"
      next
    end

    if line =~ /^#+(\s+.*)/
      line = "##" + Regexp.last_match(1)
    elsif line =~ %r{.*(https://qiita-image-store.*)[\)\"]}
      url = Regexp.last_match(1)
      ext = File.extname(url)
      local_file = "image#{image_index}#{ext}"
      image_file = dir + "/" + local_file
      image_index += 1
      File.open(image_file, "w") do |f|
        URI.open(url) do |img|
          puts "Download from #{url} to #{image_file}"
          f.write(img.read)
        end
      end
      line = "![#{local_file}](#{local_file})"
    elsif line =~ /```(.*):.*/
      line = "```" + Regexp.last_match(1)
    end
    str = str + line + "\n"
  end
  str
end

def latest?(article, dir)
  unless File.directory?(dir)
    puts "Create direcotry #{dir}"
    Dir.mkdir(dir)
    return false
  end
  filename = dir + "/README.md"
  return false unless File.exist?(filename)

  file_date = File::Stat.new(filename).mtime
  article_date = Time.iso8601(article["updated_at"])
  file_date > article_date
end

def dump_data(article, dir)
  return false if latest?(article, dir)

  filename = dir + "/README.md"
  File.open(filename, "w") do |f|
    f.puts "# #{article['title']}"
    f.puts
    body = qiita2gh(article["body"], dir)
    f.puts body
  end
  true
end

def check_dirlist(data)
  dirlist = {}
  if File.exist?(DIRLIST)
    dirlist = YAML.safe_load(File.open(DIRLIST))
  else
    puts "#{DIRLIST} is not found. Created it."
  end
  created = {}
  data.each do |d|
    title = d["title"]
    created[title] = d["created_at"]
    unless dirlist.key?(title)
      puts "New article: #{title}"
      dirlist[title] = nil
    end
  end
  keys = dirlist.keys
  keys.sort! { |a, b| created[b] <=> created[a] }
  sorted_dirlist = []
  keys.each do |title|
    sorted_dirlist.push [title, dirlist[title]]
  end
  dirlist = sorted_dirlist.to_h
  YAML.dump(dirlist, File.open(DIRLIST, "w"))
  dirlist
end

def sync(data, dirlist)
  updated = 0
  data.each do |article|
    title = article["title"]
    if dirlist[title]
      dir = dirlist[title]
      updated += 1 if dump_data(article, dir)
    end
  end
  if updated.zero?
    puts "Nothing to be done."
  else
    puts "Updated #{updated} article(s)."
  end
end

DIRLIST = "dirlist.yaml".freeze
data = YAML.safe_load(File.open("qiita.yaml"))
dirlist = check_dirlist(data)
sync(data, dirlist)
