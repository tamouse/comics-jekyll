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
$logger = Logger.new(File.join(ROOT,'log','rake.log'))
$logger.level = Logger::DEBUG

config = YAML.load(File.read(File.join(ROOT,"_config.yml")))

source         = config.delete("source")        || "source"
destination    = config.delete("destination")   || "public"
posts_dir      = config.delete("posts")         || "_posts"
download_dir   = config.delete("download_path") || "images"
home_page      = config.delete("home_page")     || "index.html"

timestamp      = Time.now.to_s

CLOBBER_LIST = [Dir[File.join(ROOT,destination,'**','*')],
                Dir[File.join(ROOT,source,posts_dir,'**','*')],
                Dir[File.join(ROOT,source,download_dir,'**','*')],
                File.join(ROOT,source,"index.html"),
                File.join(ROOT,".last_run.yaml"),
               ].flatten.select{|fn| File.exists? fn}.compact

task :default => :update

  
@run_data = {}
@run_data[:run_date] = timestamp

desc "Nightly Update"
task :update => [:go_fetch, :get_files, :write_posts, :write_today_post, :replace_home_page] do
  system "jekyll build"
  File.write('.last_run.yaml',@run_data.to_yaml)
end

desc "retrieve go comics"
task :go_fetch do |t|

  @comics = []

  # TODO throw this into _config.yml
  go_comics      = %w[nonsequitur calvinandhobbes doonesbury pearlsbeforeswine dilbert-classics culdesac
stonesoup roseisrose darksideofthehorse tomthedancingbug heartofthecity getfuzzy pickles skinhorse ozy-and-millie
overthehedge onebighappy forbetterorworse preteena]

  go_comics.each do |s|
    $logger.info "getting comic #{s}".tap{|t| puts t}
    begin
      @comics << Scrapers::GoComics.scrape(s)
    rescue Exception => e
      $logger.error "Error retrieving #{s}".tap{|t| puts t}
      $logger.debug "#{e.class}: #{e}"
      $logger.debug e.backtrace.join("\n")
      @comics << {:comic => s, :errors => {:error => true, :error_type => e.class.to_s, :message => e.to_s, :backtrace => e.backtrace.dup}}
      next
    end
  end

  @run_data[:comics] = @comics

end

desc "Get the comic files"
task :get_files => :go_fetch do
  FileUtils.mkdir_p File.join source,download_dir
  @comics.each do |comic|
    next if comic[:errors]
    $logger.info "retrieving comic file #{comic[:img_src]}".tap{|t| puts t}
    begin
      download = Scrapers::Download.download(comic[:img_src],File.join(source,download_dir))
    rescue Exception => e
      $logger.error "Error getting file #{comic[:filename]}".tap{|t| puts t}
      $logger.debug "#{e.class}: #{e}".tap{|t| puts t}
      $logger.debug e.backtrace.join("\n")
      comic[:errors] = {:error => true, :error_type => e.class.to_s, :message => e.to_s, :backtrace => e.backtrace.dup}
      next
    end
    comic[:filename] = File.basename(download)
  end
end

desc "Write the posts for this fetch"
task :write_posts => :get_files do
  FileUtils.mkdir_p File.join(source,posts_dir)
  @comics.each do |comic|
    if comic[:errors]
      write_error(comic,source,posts_dir)
    else
      write_post(comic,source,posts_dir)
    end
  end
end

def write_post(comic,source,posts_dir)
  filename = File.join(source,posts_dir,"#{comic[:pubdate]}-#{comic[:title].to_url}.html")
    
  $logger.info "Creating post #{filename}".tap{|t| puts t}
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

def write_error(comic,source,posts_dir)

  front_matter = {"layout" => "error.html",
    "title" => "Error report for retrieving #{comic[:comic]}",
    "comic" => comic[:comic]
  }

  filename = File.join(source,posts_dir,"#{Time.now.strftime("%Y-%m-%d")}-#{comic[:comic].to_url}-error.markdown")
  $logger.info "Writing error report #{filename}".tap{|t| puts t}
  File.open(filename,'w') do |error_report|
    error_report.puts front_matter.to_yaml
    error_report.puts "---"
    error_report.puts "### Error processing {{ page.comic }}\n\n"
    error_report.puts "#{comic[:errors][:message]}\n\n"
    comic[:errors][:backtrace].each do |line|
      error_report.puts "    " + line
    end
    error_report.puts comic[:errors].inspect
  end

end

desc "Write today's comics for the current update"
task :write_today_post => :write_posts do
  filename = File.join(source,posts_dir,"#{Time.now.strftime("%Y-%m-%d")}-today-s-comics.html")
  File.unlink(filename) if File.exists?(filename)
  File.open(filename,'w') do |file|
    file.puts <<-EOT
---
layout: default
---
<h1>Comics for #{Time.now.strftime("%d %m %Y")}</h1>
EOT


    FORMAT = <<-EOT
<h2>%s <small>%s</small></h2><div class="post"><img src="/#{download_dir}/%s"></div>
EOT

    @comics.each do |comic|
      next if comic[:errors]
      file.printf FORMAT, comic[:title], comic[:pubdate], comic[:filename]
    end

    file.puts "<footer>Site updated at #{timestamp}</footer>"
  end

  @run_data[:todays_post] = filename

end

desc "Replace the home page with the latest page update"
task :replace_home_page do
  actual_home_page = File.join(ROOT,source,home_page)
  todays_post = File.join(ROOT,@run_data[:todays_post])
  $logger.debug "todays_post: #{todays_post}"
  File.unlink(actual_home_page) if File.exists?(actual_home_page)
  $logger.info "Creating home page #{actual_home_page} from today's post #{todays_post}".tap{|t| puts t}
  raise "#{actual_home_page} exists!?!?!" if File.exists?(actual_home_page)
  File.symlink(todays_post, actual_home_page)
end



desc "Clobber all generated files"
task :clobber do
  if CLOBBER_LIST.empty?
    $logger.info "nothing to clobber".tap{|t| puts t}
    exit
  end
  
  puts "Clobbering: #{CLOBBER_LIST.join(" ")}"
  print "Ok? "
  resp = $stdin.gets.chomp
  if (resp =~ /^y/i)
    CLOBBER_LIST.each do |fn|
      $logger.info "unlinking #{fn}".tap{|t| puts t}
      File.unlink(fn) rescue nil
    end
  end
  
end
