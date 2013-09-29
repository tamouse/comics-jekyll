require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'erb'
require 'scrapers'
require 'awesome_print'
require 'logger'
require 'stringex'


ROOT = File.dirname(__FILE__)
FileUtils.mkdir_p(File.join(ROOT,'log'))
logger = Logger.new(File.join(ROOT,'log','rake.log'))
logger.level = Logger::DEBUG

config = YAML.load(File.read(File.join(ROOT,"_config.yml")))

source         = config.delete("source")      || "source"
destination    = config.delete("destination") || "public"
posts_dir      = config.delete("posts")       || "_posts"
download_dir   = config.delete("images")      || "images"

timestamp      = Time.now.to_s

task :default => :update

desc "Nightly Update"
task :update => [:go_fetch, :get_files, :write_posts, :write_index] do
  system "jekyll build"
  
  run_data = {}
  run_data[:run_date] = timestamp
  run_data[:comics] = @comics
  File.write('.last_run.yaml',run_data.to_yaml)
end

desc "retrieve go comics"
task :go_fetch do |t|

  @comics = []

  go_comics      = %w[nonsequitur calvinandhobbes doonesbury pearlsbeforeswine dilbert-classics culdesac
stonesoup roseisrose darksideofthehorse tomthedancingbug heartofthecity getfuzzy pickles skinhorse ozy-and-millie
overthehedge onebighappy forbetterorworse preteena]

  go_comics.each do |s|
    logger.info "getting comic #{s}\n".tap(&:display)
    begin
      @comics << Scrapers::GoComics.scrape(s)
      @comics.last[:comic] = s
    rescue Exception => e
      logger.error "Error retrieving #{s}\n".tap(&:display)
      logger.debug "#{e.class}: #{e}\n"
      logger.debug e.backtrace.join("\n")
    end
  end

end

desc "Get the comic files"
task :get_files => :go_fetch do
  @comics.each do |comic|
    logger.info "retrieving comic file #{comic[:img_src]}\n".tap(&:display)
    begin
      download = Scrapers::Download.download(comic[:img_src],File.join(source,download_dir))
    rescue Exception => e
      logger.error "Error getting file #{comic[:filename]}\n".tap(&:display)
      logger.debug "#{e.class}: #{e}\n"
      logger.debug e.backtrace.join("\n")
    end
    comic[:filename] = File.basename(download)
  end
end

desc "Write the posts for this fetch"
task :write_posts => :get_files do
  FileUtils.mkdir_p File.join(source,posts_dir)
  @comics.each do |comic|
    filename = File.join(source,posts_dir,"#{comic[:pubdate]}-#{comic[:title].to_url}.html")
    
    puts "Creating post #{filename}"
    File.open(filename,'w') do |post|
      post.puts <<-EOT
---
layout: comic
title: "#{comic[:title]}"
date: "#{comic[:pubdate]}"
source_url: #{comic[:url]}
img_src: #{comic[:img_src]}
filename: #{comic[:filename]}
post_path: #{filename}
category: #{comic[:comic]}
---
EOT
    end
  end
end

desc "Write index for the current update"
task :write_index => :write_posts do
  index = File.join(source,'index.html')
  File.unlink(index) if File.exists?(index)
  File.open(index,'w') do |file|
    file.puts <<-EOT
---
layout: default
---
<h1>Latest Comics</h1>
EOT
    FORMAT = <<-EOT
<h2>%s <small>%s</small></h2><div class="post"><img src="/comics/%s"></div>
EOT

    @comics.each do |comic|
      file.printf FORMAT, comic[:title], comic[:pubdate], comic[:filename]
    end

    file.puts "<footer>Site updated at #{timestamp}</footer>"
  end

end

desc "Clobber all generated files"
task :clobber do
  system "/bin/rm -vrf #{destination}/*"
  system "/bin/rm -vrf #{source}/#{posts_dir}/*"
  system "/bin/rm -vrf #{source}/index.html"
  system "/bin/rm -vrf #{source}/#{download_dir}/*"
end
