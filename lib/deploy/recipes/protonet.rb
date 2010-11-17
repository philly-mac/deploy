require 'fileutils'
require 'erb'

module Deploy
  module Recipes
    class Protonet < ::Deploy::Recipes::Base

      class << self

        def setup(config)
          self.config = config
          prepare_code
          move_config_to_shared
          bundle
          setup_db
          link_current
          deploy_monit
          restart_apache
        end

        def deploy(config)
          self.config = config
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

        protected

        def monit_command
          "monit -c #{config.shared_path}/config/monit_ptn_node -l #{config.shared_path}/log/monit.log -p #{config.shared_path}/pids/monit.pid"
        end

        def deploy_monit
          # variables for erb
          shared_path   = config.shared_path
          current_path  = config.current_path

          File.open("#{config.shared_path}/config/monit_ptn_node", 'w') do |f|
            f.write(ERB.new(IO.read("#{latest_deploy}/config/monit/monit_ptn_node.erb")).result(binding))
          end

          system "chmod 700 #{config.shared_path}/config/monit_ptn_node"

          # and restart monit
          system monit_command + " quit"
          sleep 2
          system monit_command
          sleep 2
        end

        # todo: replace by app configuration & remove
        def copy_stage_config
          run "if [ -f #{release_path}/config/stage_configs/#{stage}.rb ]; then cp #{release_path}/config/stage_configs/#{stage}.rb #{release_path}/config/environments/stage.rb; fi"
        end

        def create_directories
          create_directory "#{config.shared_path}/log"
          create_directory "#{config.shared_path}/db"
          create_directory "#{config.shared_path}/system"
          create_directory "#{config.shared_path}/config"
          create_directory "#{config.shared_path}/config/monit.d"
          create_directory "#{config.shared_path}/config/hostapd.d"
          create_directory "#{config.shared_path}/config/dnsmasq.d"
          create_directory "#{config.shared_path}/config/ifconfig.d"
          create_directory "#{config.shared_path}/config/protonet.d"
          create_directory "#{config.shared_path}/solr/data"
          create_directory "#{config.shared_path}/user-files", 0770
          create_directory "#{config.shared_path}/pids", 0770
          create_directory "#{config.shared_path}/avatars", 0770
        end

        def link_shared_directories
          FileUtils.rm_rf   "#{latest_deploy}/log"
          FileUtils.rm_rf   "#{latest_deploy}/public/system"
          FileUtils.rm_rf   "#{latest_deploy}/tmp/pids"
          FileUtils.mkdir_p "#{latest_deploy}/public"
          FileUtils.mkdir_p "#{latest_deploy}/tmp"
          FileUtils.ln_s    "#{config.shared_path}/log",    "#{latest_deploy}/log"
          FileUtils.ln_s    "#{config.shared_path}/system", "#{latest_deploy}/public/system"
          FileUtils.ln_s    "#{config.shared_path}/pids",   "#{latest_deploy}/tmp/pids"
        end

        def create_directory(dir_name, permissions = nil)
          FileUtils.mkdir_p dir_name
          FileUtils.chmod permissions, dir_name if permissions
        end

        def move_config_to_shared
          system("mv ~/deploy_config #{config.shared_path}/config/protonet.d/deploy_config")
        end

        def setup_db
          FileUtils.cd latest_deploy do
            db_exists = system("mysql -u root #{config.database_name} -e 'show tables;' 2>&1 > /dev/null")
            if !db_exists
              puts "db not found, creating: #{ system("export RAILS_ENV=#{config.env}; bundle exec rake db:setup") ? "success!" : "FAIL!"}"
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
          system "rm -f /tmp/dashboard.tar.gz"
          system("wget http://releases.protonet.info/release/get/#{config.key} -O dashboard.tar.gz") && unpack
        end

        def release_dir
          FileUtils.mkdir_p config.releases_path if !File.exists? config.releases_path
        end

        def unpack
          release_dir
          if File.exists?("/tmp/dashboard.tar.gz")
            FileUtils.cd "/tmp"
            FileUtils.rm_rf "/tmp/dashboard"
            system "tar -xzf #{"/tmp/dashboard.tar.gz"}"
            release_timestamp = "#{config.releases_path}/#{Time.now.strftime('%Y%m%d%H%M%S')}"
            FileUtils.mkdir_p release_timestamp
            system "mv /tmp/dashboard/* #{release_timestamp}"
          end
        end

        def clean_up
          all_releases = Dir["#{config.releases_path}/*"].sort
          if (num_releases = all_releases.size) >= config.max_num_releases
            num_to_delete = num_releases - config.max_num_releases

            num_to_delete.times do
              FileUtils.rm_rf "#{all_releases.delete_at(0)}"
            end
          end
        end

        def bundle
          shared_dir  = File.expand_path('bundle', config.shared_path)
          release_dir = File.expand_path('.bundle', latest_deploy)

          FileUtils.mkdir_p shared_dir
          FileUtils.ln_s shared_dir, release_dir

          FileUtils.cd latest_deploy

          system "bundle check 2>&1 > /dev/null"

          if $?.exitstatus != 0
            system "bundle install --without test --without cucumber"
          end
        end

        def migrate
          FileUtils.cd latest_deploy
          system "export RAILS_ENV=#{config.env}; bundle exec rake db:migrate"
        end

        def link_current
          FileUtils.rm_f config.current_path
          FileUtils.ln_s latest_deploy, config.current_path
        end

        def restart_apache
          FileUtils.touch "#{config.current_path}/tmp/restart.txt"
        end

        def restart_services
          system monit_command + " -g daemons restart all"
        end

        def latest_deploy
          Dir["#{config.releases_path}/*"].sort.last
        end

      end
    end
  end
end

