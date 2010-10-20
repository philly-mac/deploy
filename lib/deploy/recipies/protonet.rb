require 'fileutils'

module Deploy
  module Recipies
    class Protonet

      extend ::Deploy::Base
      extend ::Deploy::RemoteCommands

      class << self
        attr_accessor :config


        def setup(config)
          self.config = config
          create_directories
          get_code
          setup_db
        end

        def deploy(config)
          self.config = config
          get_code
          bundle
          migrate
          clean_up
          link
          restart
        end

        private

        def create_directories
          create_directory "#{config.shared_path}/log"
          create_directory "#{config.shared_path}/db"
          create_directory "#{config.shared_path}/system"
          create_directory "#{config.shared_path}/config"
          create_directory "#{config.shared_path}/config/monit.d"
          create_directory "#{config.shared_path}/config/hostapd.d"
          create_directory "#{config.shared_path}/config/dnsmasq.d"
          create_directory "#{config.shared_path}/config/ifconfig.d"
          create_directory "#{config.shared_path}/solr/data"
          create_directory "#{config.shared_path}/user-files", 0770
          create_directory "#{config.shared_path}/pids", 0770
          create_directory "#{config.shared_path}/avatars", 0770
        end

        def create_directory(dir_name, permissions = nil)
          FileUtils.mkdir_p dir_name
          FileUtils.chmod permissions, dir_name if permissions
        end

        def setup_db
          FileUtils.cd config.current_path do
            system "mysql -u root #{config.database_name} -e 'show tables;' 2>&1 > /dev/null"
            if $?.exitstatus != 0
              system "RAILS_ENV=#{config.env} bundle exec rake db:setup"
            end
          end
        end

        def get_code
          FileUtils.cd "/tmp"
          system "rm -f /tmp/release.tar.gz"
          system("wget http://cd.ivercore.com/latest/#{config.key} -O release.tar.gz") && unpack
        end

        def release_dir
          FileUtils.mkdir_p config.releases_path if !File.exists? config.releases_path
        end

        def unpack
          release_dir
          if File.exists?("/tmp/release.tar.gz")
            FileUtils.cd "/tmp"
            system "tar -xzf #{"/tmp/release.tar.gz"}"
            FileUtils.mv config.archive_name, "#{config.releases_path}/#{Time.now.strftime('%Y%m%d%H%M%S')}"
          end
        end

        def clean_up
          all_releases = Dir["#{config.releases_path}/*"].sort
          if (num_releases = all_releases.size) > config.max_num_releases
            num_to_delete = num_releases - config.max_num_releases

            num_to_delete.times do
              FileUtils.r_rf "#{config.releases_path}/#{all_releases.delete_at(0)}"
            end
          end
        end

        def bundle
          shared_dir = File.join(config.shared_path, 'bundle')
          release_dir = File.join(config.releases_path, '.bundle')

          FileUtils.mkdir_p shared_dir
          FileUtils.ln_s shared_dir, release_dir

          FileUtils.cd config.releases_path

          system "bundle check 2>&1 > /dev/null"

          if $?.exitstatus != 0
            system "bundle install --without test --without cucumber"
          end
        end

        def migrate
          FileUtils.cd config.current_path
          system "RAILS_ENV=#{env} rake db:migrate"
        end

        def link
          FileUtils.rm config.current_path
          FileUtils.ln_s config.latest_deploy, config.current_path
        end

        def restart
          FileUtils.touch "#{current_path}/tmp/restart.txt"
        end
      end
    end
  end
end

