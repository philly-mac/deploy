require 'fileutils'
require 'erb'

module Deploy
  module Recipes
    class Protonet < ::Deploy::Recipes::Base

      class << self
        def create_directory(dir_name, permissions = nil)
          FileUtils.mkdir_p dir_name
          FileUtils.chmod permissions, dir_name if permissions
        end

        def latest_deploy
          Dir["#{config.releases_path}/*"].sort.last
        end

        def monit_command(command = "")
          puts "running monit command #{command}"
          local "/usr/sbin/monit -c #{config.shared_path}/config/monit_ptn_node -l #{config.shared_path}/log/monit.log -p #{config.shared_path}/pids/monit.pid #{command}"
        end

      end

      task :setup do
        prepare_code
        bundle
        setup_db
        link_current
        deploy_monit
        restart_apache
      end

      task :deploy do
        prepare_code
        bundle
        migrate
        # copy_stage_config
        clean_up
        link_current
        deploy_monit
        restart_services
        restart_apache
      end


      job :deploy_monit do
        # variables for erb
        shared_path   = config.shared_path
        current_path  = config.current_path

        File.open("#{config.shared_path}/config/monit_ptn_node", 'w') do |f|
          f.write(ERB.new(IO.read("#{latest_deploy}/config/monit/monit_ptn_node.erb")).result(binding))
        end

        local "chmod 700 #{config.shared_path}/config/monit_ptn_node"

        # and restart monit
        monit_command "quit"
        sleep 2
        # restarts it
        monit_command
        sleep 2
        monit_command "monitor all"
        monit_command "start all"
      end

      # todo: replace by app configuration & remove
      job :copy_stage_config do
        run "if [ -f #{release_path}/config/stage_configs/#{stage}.rb ]; then cp #{release_path}/config/stage_configs/#{stage}.rb #{release_path}/config/environments/stage.rb; fi"
      end

      job :create_directories do
        create_directory "#{config.shared_path}/log"
        create_directory "#{config.shared_path}/db"
        create_directory "#{config.shared_path}/system"
        create_directory "#{config.shared_path}/config/monit.d"
        create_directory "#{config.shared_path}/config/hostapd.d"
        create_directory "#{config.shared_path}/config/dnsmasq.d"
        create_directory "#{config.shared_path}/config/ifconfig.d"
        create_directory "#{config.shared_path}/config/protonet.d"
        create_directory "#{config.shared_path}/externals/screenshots"
        create_directory "#{config.shared_path}/externals/image_proxy"
        create_directory "#{config.shared_path}/solr/data"
        create_directory "#{config.shared_path}/user-files", 0770
        create_directory "#{config.shared_path}/pids", 0770
        create_directory "#{config.shared_path}/avatars", 0770
      end

      job :link_shared_directories do
        FileUtils.rm_rf   "#{latest_deploy}/log"
        FileUtils.rm_rf   "#{latest_deploy}/public/system"
        FileUtils.rm_rf   "#{latest_deploy}/tmp/pids"
        FileUtils.mkdir_p "#{latest_deploy}/public"
        FileUtils.mkdir_p "#{latest_deploy}/tmp"
        FileUtils.ln_s    "#{config.shared_path}/log",        "#{latest_deploy}/log"
        FileUtils.ln_s    "#{config.shared_path}/system",     "#{latest_deploy}/public/system"
        FileUtils.ln_s    "#{config.shared_path}/pids",       "#{latest_deploy}/tmp/pids"
        FileUtils.ln_s    "#{config.shared_path}/externals",  "#{latest_deploy}/public/externals"
      end


      job :setup_db do
        FileUtils.cd latest_deploy do
          db_exists = local("mysql -u root #{config.database_name} -e 'show tables;' 2>&1 > /dev/null")
          if !db_exists
            puts "db not found, creating: #{ local("export RAILS_ENV=#{config.env}; bundle exec rake db:setup") ? "success!" : "FAIL!"}"
          end
        end
      end

      job :prepare_code do
        create_directories
        get_code_and_unpack
        link_shared_directories
      end

      job :get_code_and_unpack do
        FileUtils.cd "/tmp"
        local "rm -f /tmp/dashboard.tar.gz"
        local("wget http://releases.protonet.info/release/get/#{config.key} -O dashboard.tar.gz") && unpack
      end

      job :release_dir do
        FileUtils.mkdir_p config.releases_path if !File.exists? config.releases_path
      end

      job :unpack do
        release_dir
        if File.exists?("/tmp/dashboard.tar.gz")
          FileUtils.cd "/tmp"
          FileUtils.rm_rf "/tmp/dashboard"
          local "tar -xzf #{"/tmp/dashboard.tar.gz"}"
          release_timestamp = "#{config.releases_path}/#{Time.now.strftime('%Y%m%d%H%M%S')}"
          FileUtils.mkdir_p release_timestamp
          local "mv /tmp/dashboard/* #{release_timestamp}"
        end
      end

      job :clean_up do
        all_releases = Dir["#{config.releases_path}/*"].sort
        if (num_releases = all_releases.size) >= config.max_num_releases
          num_to_delete = num_releases - config.max_num_releases

          num_to_delete.times do
            FileUtils.rm_rf "#{all_releases.delete_at(0)}"
          end
        end
      end

      job :bundle do
        shared_dir  = File.expand_path('bundle', config.shared_path)
        release_dir = File.expand_path('.bundle', latest_deploy)

        FileUtils.mkdir_p shared_dir
        FileUtils.ln_s shared_dir, release_dir

        FileUtils.cd latest_deploy

        local "bundle check 2>&1 > /dev/null"

        if $?.exitstatus != 0
          local "bundle install --without test --without cucumber"
        end
      end

      job :migrate do
        FileUtils.cd latest_deploy
        local "export RAILS_ENV=#{config.env}; bundle exec rake db:migrate"
      end

      job :link_current do
        FileUtils.rm_f config.current_path
        FileUtils.ln_s latest_deploy, config.current_path
      end

      job :restart_apache do
        FileUtils.touch "#{config.current_path}/tmp/restart.txt"
      end

      job :restart_services do
        local monit_command + " -g daemons restart all"
      end

    end
  end
end

