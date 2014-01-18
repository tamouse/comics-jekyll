# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'comics'
set :repo_url, 'git@github.com:tamouse/comics-jekyll.git'
set :branch, "master"
set :deploy_to, '/home/tamara/Sites/tamouse.org/comics'
set :scm, :git
server 'comics.tamouse.org', user: 'tamara', roles: [:web, :app, :db, :workers]

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
# set :linked_dirs, %w{public source vendor/bundle tmp log config}
set :linked_dirs, %w{vendor/bundle log}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

desc "Report Uptimes"
task :uptime do
  on roles(:all) do |host|
    info "Host #{host} (#{host.roles.to_a.join(', ')}):\t#{capture(:uptime)}"
  end
end
