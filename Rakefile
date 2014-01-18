require 'rubygems'
require 'bundler/setup'

require './log4r-setup'

require 'yaml'
require 'erb'
require 'scrapers'
require 'awesome_print'
require 'stringex'
require 'active_support'
require 'highline/import'
require 'open3'

config = YAML.load(File.read(File.join(ROOT,"_config.yml")))

source         = config.delete("source")        || "source"
destination    = config.delete("destination")   || "public"
posts_dir      = config.delete("posts")         || "_posts"
download_dir   = config.delete("download_path") || "images"
home_page      = config.delete("home_page")     || "index.html"
comic_list     = config.delete("comics")        || {"go_comics" => %w[calvinandhobbes]}

@comics = []

timestamp      = Time.now.to_s

CLOBBER_LIST = [Dir[File.join(ROOT,destination,'**','*')],
                Dir[File.join(ROOT,source,posts_dir,'**','*')],
                Dir[File.join(ROOT,source,download_dir,'**','*')],
                File.join(ROOT,source,"index.html"),
                File.join(ROOT,".last_run.yaml"),
               ].flatten.select{|fn| File.exists? fn}.compact

FORMAT = %Q{
<h2>%s <small>%s</small></h2>
<div class="post">
  <img src="/#{download_dir}/%s" title="%s" alt="%s">
</div>
}

ERROR_FORMAT = %Q{
<h2>%s</h2>
<div class="post">%s</div>
}

@run_data = {}
@run_data[:run_date] = timestamp

task :default => :update

desc "Nightly Update"
task :update => [:start_update, :go_fetch, :fetch_other, :get_files,
                 :write_today_post, :replace_home_page,
                 :build_site
                ] do |t|
  
  File.write('.last_run.yaml',@run_data.to_yaml)
  Log.info "#{t.name} Completed"
end

task :start_update do |t|
  Log.info "Starting comics update"
end

desc "retrieve go comics"
task :go_fetch do |t|

  go_comics      = comic_list.fetch("go_comics",[])

  go_comics.each do |s|
    Log.info "getting comic #{s}"
    begin
      comic = Scrapers::GoComics.scrape(s)
      comic.merge({
                    "img_title" => comic[:title],
                    "img_alt"   => comic[:comic]
                  })
      @comics << comic
    rescue Exception => e
      Log.error "Error retrieving #{s}"
      Log.debug "#{e.class}: #{e}"
      Log.debug e.backtrace.join("\n")
      @comics << {:comic => s, :errors => {:error => true, :error_type => e.class.to_s, :message => e.to_s, :backtrace => e.backtrace.dup}}
      next
    end
  end

  @run_data[:comics] = @comics

end

desc "retrieve other comics"
task :fetch_other do |t|
  other_list = comic_list.fetch("other",[])
  other_list.each do |comic|
    name = comic.keys.first
    scraper = comic.values.first
    begin
      Log.info "fetching #{name}"
      scraper = ActiveSupport::Inflector.constantize("Scrapers::#{scraper}")
      result = scraper.scrape
      result[:comic] = name
      result[:title] = "#{name}: #{result[:title]}"
      @comics << result
    rescue Exception => e
      Log.error "Error retrieving #{name}"
      Log.debug "#{e.class}: #{e}"
      Log.debug e.backtrace.join("\n")
      @comics << {
        :comic => name,
        :errors => {
          :error => true,
          :error_type => e.class.to_s,
          :message => e.to_s,
          :backtrace => e.backtrace.dup
        }
      }
      next
    end
  end
end

desc "Get the comic files"
task :get_files => [:go_fetch, :fetch_other] do
  FileUtils.mkdir_p File.join source,download_dir
  @comics.each do |comic|
    next if comic[:errors]
    Log.info "retrieving comic file #{comic[:img_src]}"
    begin
      download = Scrapers::Download.download(comic[:img_src],File.join(source,download_dir),true)
    rescue Exception => e
      Log.error "Error getting file #{comic[:filename]}"
      Log.debug "#{e.class}: #{e}"
      Log.debug e.backtrace.join("\n")
      comic[:errors] = {:error => true, :error_type => e.class.to_s, :message => e.to_s, :backtrace => e.backtrace.dup}
      next
    end
    comic[:filename] = File.basename(download)
  end
end

desc "Write the posts for this fetch"
task :write_posts do
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
    
  Log.info "Creating post #{filename}"
  File.open(filename,'w') do |post|
    front_matter = {
      "layout" => "comic",
      "title" => comic[:title],
      "date" => comic[:pubdate],
      "source_url" => comic[:url],
      "img_src" => comic[:img_src],
      "filename" => comic[:filename],
      "post_path" => filename,
      "category" => comic[:comic],
      "img_title" => comic[:img_title],
      "img_alt" => comic[:img_alt],
}

    post.puts front_matter.to_yaml
    post.puts "---"
  end

end

def write_error(comic,source,posts_dir)

  front_matter = {"layout" => "error.html",
    "title" => "Error report for retrieving #{comic[:comic]}",
    "comic" => comic[:comic]
  }

  filename = File.join(source,posts_dir,"#{Time.now.strftime("%Y-%m-%d")}-#{comic[:comic].to_url}-error.markdown")
  Log.info "Writing error report #{filename}"
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
task :write_today_post do
  Log.info "Write today's comics"
  filename = File.join(source,posts_dir,"#{Time.now.strftime("%Y-%m-%d")}-today-s-comics.html")
  File.unlink(filename) if File.exists?(filename)
  title = "Comics for #{Time.now.strftime("%d %m %Y")}"
  File.open(filename,'w') do |file|
    file.puts <<-EOT
---
layout: default
title: #{title}
date: #{Time.now}
---
<h1>#{title}</h1>
EOT
    @comics.each do |comic|
      if comic[:errors]
        file.printf ERROR_FORMAT, comic[:title], comic[:errors][:message]
        write_error(comic,source,posts_dir)
      else
        file.printf FORMAT, comic[:title], comic[:pubdate], comic[:filename], comic[:img_title], comic[:img_alt]
      end
    end

    file.puts "<footer>Site updated at #{timestamp}</footer>"
  end

  @run_data[:todays_post] = filename

end

desc "Replace the home page with the latest page update"
task :replace_home_page do
  actual_home_page = File.join(ROOT,source,home_page)
  Log.debug "actual_home_page: #{actual_home_page}"
  todays_post = File.join(ROOT,@run_data[:todays_post])
  Log.debug "todays_post: #{todays_post}"
  FileUtils.rm_f(actual_home_page)
  Log.debug "Dir[actual_home_page]: #{Dir[actual_home_page]}"
  Log.info "Creating home page #{actual_home_page} from today's post #{todays_post}"
  raise "#{actual_home_page} exists!?!?!" if File.exists?(actual_home_page)
  File.symlink(todays_post, actual_home_page)
end

desc "Build the site with Jekyll"
task :build_site do |t|
  Log.info "Building site"
  cap_out, cap_status = Open3.capture2e("jekyll build")
  if cap_status.success?
    Log.info "Jekyll succeeded"
    Log.debug cap_out
  else
    Log.error "Jekyll failed: Error: #{cap_status}"
    Log.debug cap_out
  end
end

desc "Clobber all generated files"
task :clobber do
  if CLOBBER_LIST.empty?
    Log.info "nothing to clobber"
  else
    say "Clobbering: #{CLOBBER_LIST.join(" ")}"
    if ask("Ok?  ") {|q| q.validate = /\A[yn]\z/i ; }.downcase == 'y'
      CLOBBER_LIST.each do |fn|
        Log.info "unlinking #{fn}"
        File.unlink(fn) rescue nil
      end
    end
  end
end
