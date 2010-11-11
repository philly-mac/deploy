module Deploy
  module Recipes
    class Padrino

      extend ::Deploy::Base
      extend ::Deploy::RemoteCommands

      class << self
        attr_accessor :config

        def setup(config)
          self.config = config
          create_directories
          setup_db
        end

        def deploy(config)
          self.config = config
          get_and_pack_code
          push_code
          unpack
          link
          bundle
          auto_upgrade
          clean_up
          restart
        end

        private

        def create_directories
          mkdir "#{config.shared_path}/log"
          mkdir "#{config.shared_path}/config"
          mkdir "#{config.shared_path}/vendor"
          mkdir "#{config.shared_path}/tmp"
          mkdir "#{config.releases_path}"
          push!
        end

        def get_and_pack_code
          local "cd #{config.local_root}"
          local "git pull"
          local "tar --exclude='.git' --exclude='log' --exclude='vendor' -cjf /tmp/#{config.app_name}.tar.bz2 *"
        end

        def push_code
          local "rsync #{config.extra_rsync_options} /tmp/#{config.app_name}.tar.bz2 #{config.username}@#{config.remote}:/tmp/"
        end

        def setup_db
          on_bad_exit "mysql -u root -p #{config.database_password} #{config.database} -e 'show tables;' 2>&1 > /dev/null",
            [
              "cd #{config.current_path}",
              "PADRINO_ENV=#{config.env} bundle exec rake db:setup"
            ]
          push!
        end

        def unpack
          release_stamp = Time.now.strftime('%Y%m%d%H%M%S')
          on_good_exit file_exists("/tmp/#{config.app_name}.tar.bz2", false),
            [
              "cd #{config.releases_path}",
              "mkdir #{release_stamp}",
              "cd #{release_stamp}",
              "tar -xjf /tmp/#{config.app_name}.tar.bz2",
            ]
          push!
        end

        def link
          remote "cd #{config.releases_path}"
          remote "rm #{config.current_path}"
          remote "for i in $( ls -rl -m1 ); do LATEST_RELEASE=$i; break; done"
          remote "ln -s #{config.releases_path}/$LATEST_RELEASE #{config.current_path}"
          remote "ln -s #{config.shared_path}/log $LATEST_RELEASE/log"
          remote "ln -s #{config.shared_path}/vendor $LATEST_RELEASE/vendor"
          remote "ln -s #{config.shared_path}/tmp $LATEST_RELEASE/tmp"
          push!
        end

        def bundle
          remote "cd #{config.current_path}"
          remote "bundle install --without test --deployment"
        end

        def clean_up
          remote "cd #{config.releases_path}"
          remote "export NUM_RELEASES=`ls -trl -m1 | wc -l`"
          remote "export NUM_TO_REMOVE=$(( $NUM_RELEASES - #{config.max_num_releases} ))"
          remote "export COUNTER=1"
          on_good_exit "[ $NUM_TO_REMOVE =~ ^[0-9]+$ ] && [ $COUNTER =~ ^[0-9]+$ ] && [ $NUM_TO_REMOVE -ge 1 ]",
            [
              "for i in $( ls -tlr -m1 ); do echo rm -rf $i [ $COUNTER == $NUM_TO_REMOVE ] && break; COUNTER=$(( $COUNTER + 1 )) done",
            ]
          push!
        end

        def auto_upgrade
          remote "cd #{config.current_path}"
          remote "PADRINO_ENV=#{config.env} padrino rake dm:auto:upgrade"
          push!
        end

        def auto_migrate
          remote "cd #{config.current_path}"
          remote "PADRINO_ENV=#{config.env} padrino rake dm:auto:migrate"
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

