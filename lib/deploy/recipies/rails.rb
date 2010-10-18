module Deploy
  module Recipies
    class Rails

      extend ::Deploy::Base
      extend ::Deploy::RemoteCommands

      class << self
        attr_accessor :config

        def first_run(config)
          self.config = config
          create_directories
          setup_db
        end

        def deploy(config)
          self.config = config
          get_code
          release_dir
          unpack
          bundle
          migrate
          clean_up
          link
          restart
        end

        private

        def create_directories
          mkdir "config.shared_path}/log"
          mkdir "config.shared_path}/db"
          mkdir "config.shared_path}/system"
          mkdir "config.shared_path}/config"
          mkdir "config.shared_path}/config/monit.d"
          mkdir "config.shared_path}/config/hostapd.d"
          mkdir "config.shared_path}/config/dnsmasq.d"
          mkdir "config.shared_path}/config/ifconfig.d"
          mkdir "config.shared_path}/solr/data"
          mkdir "config.shared_path}/user-files", 0770
          mkdir "config.shared_path}/pids", 0770
          mkdir "config.shared_path}/avatars", 0770
          push!
        end

        def setup_db
          on_bad_exit "mysql -u root dashboard_production -e 'show tables;' 2>&1 > /dev/null",
            [
              "cd #{config.current_path}",
              "RAILS_ENV=#{config.env} bundle exec rake db:setup"
            ]
          push!
        end

        def release_dir
          on_good_exit file_not_exists(config.shared_path, false),
            [[:mkdir, ["#{config.shared_path}",nil,false]]]

          on_good_exit file_not_exists(config.releases_path, false),
            [[:mkdir, ["#{config.releases_path}",nil,false]]]
          push!
        end

        def unpack
          on_good_exit file_exists("/tmp/#{config.archive_name}#{config.packing_type}", false),
            [
              "cd /tmp ",
              "tar -xzf #{config.archive_name}#{config.packing_type}",
              "mv #{config.archive_name} #{config.release_path}/#{Time.now.strftime('%Y%m%d%H%M%S')}"
            ]
          push!
        end

        def clean_up
          all_releases = Dir["#{config.release_path}/*"].sort
          if (num_releases = all_releases.size) > MAX_NUM_RELEASES
            num_to_delete = num_releases - MAX_NUM_RELEASES

            num_to_delete.times do
              FileUtils.r_rf "#{config.release_path}/#{all_releases.delete_at(0)}"
            end
          end
        end

        def bundle
          shared_dir = File.join(config.shared_path, 'bundle')
          release_dir = File.join(config.release_path, '.bundle')

          FileUtils.mkdir_p shared_dir
          FileUtils.ln_s shared_dir, release_dir

          FileUtils.cd config.release_path

          system "bundle check 2>&1 > /dev/null"

          if $?.exitstatus != 0
            system "bundle install --without test --without cucumber"
          end
        end

        def migrate
          FileUtils.cd config.current_path
          system "RAILS_ENV=#{config.env} rake db:migrate"
        end

        def link
          remote "rm #{config.current_path}"
          remote "ln -s #{lateset_deploy} #{config.current_path}"
          push!
        end

        def restart
          remote "touch #{config.current_path}/tmp/restart.txt"
          push!
        end
      end
    end
  end
end
