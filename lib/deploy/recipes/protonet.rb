require 'fileutils'
require 'erb'

module Deploy
  module Recipes
    class Protonet < ::Deploy::Recipes::Base

      def create_directory(dir_name, permissions = nil)
        FileUtils.mkdir_p dir_name
        FileUtils.chmod permissions, dir_name if permissions
      end

      def latest_deploy
        Dir["#{config.get(:releases_path)}/*"].sort.last
      end

      def monit_command(command = "")
        puts "\nrunning monit command #{command}"
        run_now! "/usr/sbin/monit -c #{config.get(:shared_path)}/config/monit_ptn_node -l #{config.get(:shared_path)}/log/monit.log -p #{config.get(:shared_path)}/pids/monit.pid #{command}"
      end

      def bundle_cleanup
        "unset RUBYOPT;unset GEM_HOME; unset GEM_PATH; unset BUNDLE_GEMFILE"
      end

      def setup
        self.actions = [
          :prepare_code,
          :bundle,
          :setup_db,
          :link_current,
          :deploy_monit,
          :restart_apache
        ]
        run_actions
      end

      def deploy
        self.actions = [
          :prepare_code,
          :bundle,
          :migrate,
          # :copy_stage_config,
          :clean_up,
          :link_current,
          :deploy_monit,
          :restart_services,
          :restart_apache,
        ]
        run_actions
      end

      def deploy_monit
        # variables for erb
        shared_path   = config.get(:shared_path)
        current_path  = config.get(:current_path)

        File.open("#{config.get(:shared_path)}/config/monit_ptn_node", 'w') do |f|
          f.write(ERB.new(IO.read("#{latest_deploy}/config/monit/monit_ptn_node.erb")).result(binding))
        end

        run_now! "chmod 700 #{config.get(:shared_path)}/config/monit_ptn_node"

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
      def copy_stage_config
        run "if [ -f #{release_path}/config/stage_configs/#{stage}.rb ]; then cp #{release_path}/config/stage_configs/#{stage}.rb #{release_path}/config/environments/stage.rb; fi"
      end

      def create_directories
        create_directory "#{config.get(:shared_path)}/log"
        create_directory "#{config.get(:shared_path)}/db"
        create_directory "#{config.get(:shared_path)}/system"
        create_directory "#{config.get(:shared_path)}/config/monit.d"
        create_directory "#{config.get(:shared_path)}/config/hostapd.d"
        create_directory "#{config.get(:shared_path)}/config/dnsmasq.d"
        create_directory "#{config.get(:shared_path)}/config/ifconfig.d"
        create_directory "#{config.get(:shared_path)}/config/protonet.d"
        create_directory "#{config.get(:shared_path)}/externals/screenshots"
        create_directory "#{config.get(:shared_path)}/externals/image_proxy"
        create_directory "#{config.get(:shared_path)}/solr/data"
        create_directory "#{config.get(:shared_path)}/user-files", 0770
        create_directory "#{config.get(:shared_path)}/pids", 0770
        create_directory "#{config.get(:shared_path)}/avatars", 0770
      end

      def link_shared_directories
        FileUtils.rm_rf   "#{latest_deploy}/log"
        FileUtils.rm_rf   "#{latest_deploy}/public/system"
        FileUtils.rm_rf   "#{latest_deploy}/tmp/pids"
        FileUtils.mkdir_p "#{latest_deploy}/public"
        FileUtils.mkdir_p "#{latest_deploy}/tmp"
        FileUtils.ln_s    "#{config.get(:shared_path)}/log",        "#{latest_deploy}/log"
        FileUtils.ln_s    "#{config.get(:shared_path)}/system",     "#{latest_deploy}/public/system"
        FileUtils.ln_s    "#{config.get(:shared_path)}/pids",       "#{latest_deploy}/tmp/pids"
        FileUtils.ln_s    "#{config.get(:shared_path)}/externals",  "#{latest_deploy}/public/externals"
      end


      def setup_db
        FileUtils.cd latest_deploy do
          db_exists = run_now!("mysql -u root #{config.get(:database_name)} -e 'show tables;' 2>&1 > /dev/null")
          if !db_exists
            puts "db not found, creating: #{ run_now!("#{bundle_cleanup}; export RAILS_ENV=#{config.get(:env)}; bundle exec rake db:setup") ? "success!" : "FAIL!"}"
          end
        end
      end

      def prepare_code
        create_directories
        get_code_and_unpack
        link_shared_directories
      end

      def get_code_and_unpack
        FileUtils.cd "/tmp"
        run_now! "rm -f /tmp/dashboard.tar.gz"
        run_now!("wget http://releases.protonet.info/release/get/#{config.get(:key)} -O dashboard.tar.gz") && unpack
      end

      def release_dir
        FileUtils.mkdir_p config.get(:releases_path) if !File.exists? config.get(:releases_path)
      end

      def unpack
        release_dir
        if File.exists?("/tmp/dashboard.tar.gz")
          FileUtils.cd "/tmp"
          FileUtils.rm_rf "/tmp/dashboard"
          run_now! "tar -xzf #{"/tmp/dashboard.tar.gz"}"
          release_timestamp = "#{config.get(:releases_path)}/#{Time.now.strftime('%Y%m%d%H%M%S')}"
          FileUtils.mkdir_p release_timestamp
          run_now! "mv /tmp/dashboard/* #{release_timestamp}"
        end
      end

      def clean_up
        all_releases = Dir["#{config.get(:releases_path)}/*"].sort
        if (num_releases = all_releases.size) >= config.get(:max_num_releases)
          num_to_delete = num_releases - config.get(:max_num_releases)

          num_to_delete.times do
            FileUtils.rm_rf "#{all_releases.delete_at(0)}"
          end
        end
      end

      def bundle
        shared_dir  = File.expand_path('bundle', config.get(:shared_path))
        release_dir = File.expand_path('.bundle', latest_deploy)

        FileUtils.mkdir_p shared_dir
        FileUtils.ln_s shared_dir, release_dir

        FileUtils.cd latest_deploy

        run_now! "#{bundle_cleanup}; bundle check 2>&1 > /dev/null ; if [ $? -ne 0 ] ; then sh -c \"bundle install --without=test:cucumber\" ; fi"
      end

      def migrate
        FileUtils.cd latest_deploy
        run_now! "#{bundle_cleanup}; export RAILS_ENV=#{config.get(:env)}; bundle exec rake db:migrate"
      end

      def link_current
        FileUtils.rm_f config.get(:current_path)
        FileUtils.ln_s latest_deploy, config.get(:current_path)
      end

      def restart_apache
        FileUtils.touch "#{config.get(:current_path)}/tmp/restart.txt"
      end

      def restart_services
        monit_command "-g daemons restart all"
      end

    end
  end
end

