module Deploy
  module Recipes
    class PadrinoDataMapper < ::Deploy::Recipes::Base

      class << self

        def setup(config)
          self.config = config
          create_directories
        end

        def create_db
          setup_db
          auto_migrate
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

        protected

        def create_directories(delay_push = false)
          mkdir "#{config.shared_path}/log"
          mkdir "#{config.shared_path}/config"
          mkdir "#{config.shared_path}/vendor"
          mkdir "#{config.shared_path}/tmp"
          mkdir "#{config.releases_path}"
          remote "echo \"rvm --create use default@#{config.gemset_name}\" > #{config.app_root}/.rvmrc"
          push! unless delay_push
        end

        def get_and_pack_code(delay_push = false)
          local "cd #{config.local_root}"
          local "git pull"
          local "tar --exclude='.git' --exclude='log' --exclude='vendor' -cjf /tmp/#{config.app_name}.tar.bz2 *"
        end

        def push_code(delay_push = false)
          local "rsync #{config.extra_rsync_options} /tmp/#{config.app_name}.tar.bz2 #{config.username}@#{config.remote}:/tmp/"
        end

        def setup_db(delay_push = false)
          "cd #{config.current_path}"
          "bundle exec padrino rake dm:create -e #{config.env}"
          push! unless delay_push
        end

        def unpack(delay_push = false)
          release_stamp = Time.now.strftime('%Y%m%d%H%M%S')
          file_exists "/tmp/#{config.app_name}.tar.bz2",
            [
              "cd #{config.releases_path}",
              "mkdir #{release_stamp}",
              "cd #{release_stamp}",
              "tar -xjf /tmp/#{config.app_name}.tar.bz2",
            ]
            remote "chown -Rf #{config.remote_user}:#{config.remote_group} #{config.app_root}"
            remote "find #{config.current_path} -type d -exec chmod 775 '{}' \\;"
            remote "find #{config.current_path} -type f -exec chmod 664 '{}' \\;"
            remote "find #{config.shared_path}/vendor -type d -name \"bin\" -exec chmod -Rf 775 '{}' \\;"
          push! unless delay_push
        end

        def link(delay_push = false)
          remote "for i in $( ls -rl -m1 #{config.releases_path} ); do LATEST_RELEASE=$i; break; done"

          link_exists(config.current_path, [ "rm #{config.current_path}" ])
          link_not_exists("#{config.releases_path}/$LATEST_RELEASE", ["ln -s #{config.releases_path}/$LATEST_RELEASE #{config.current_path}"])
          link_not_exists("#{config.shared_path}/log", ["ln -s #{config.shared_path}/log #{config.releases_path}/$LATEST_RELEASE/log"])
          link_not_exists("#{config.shared_path}/vendor", ["ln -s #{config.shared_path}/vendor #{config.releases_path}/$LATEST_RELEASE/vendor"])
          link_not_exists("#{config.shared_path}/tmp", ["ln -s #{config.shared_path}/tmp #{config.releases_path}/$LATEST_RELEASE/tmp"])
          push! unless delay_push
        end

        def bundle(delay_push = false)
          remote "source /usr/local/lib/rvm"
          remote "rvm rvmrc trust #{config.app_root}"
          remote "cd #{config.current_path}"
          remote "bundle install --without test --deployment"
          push! unless delay_push
        end

        def clean_up(delay_push = false)
          remote "cd #{config.releases_path}"
          remote "export NUM_RELEASES=`ls -trl -m1 | wc -l`"
          remote "export NUM_TO_REMOVE=$(( $NUM_RELEASES - #{config.max_num_releases} ))"
          remote "export COUNTER=1"
          on_good_exit "[[ $NUM_TO_REMOVE =~ ^[0-9]+$ ]] && [[ $COUNTER =~ ^[0-9]+$ ]] && [[ $NUM_TO_REMOVE -ge 1 ]]",
            [
              "for i in $( ls -tlr -m1 ); do echo \"removing $i\"; rm -rf $i; [[ $COUNTER == $NUM_TO_REMOVE ]] && break; COUNTER=$(( $COUNTER + 1 )); done",
            ]
          push! unless delay_push
        end

        def auto_upgrade(delay_push = false)
          remote "cd #{config.current_path}"
          remote "padrino rake dm:auto:upgrade -e #{config.env}"
          push!
        end

        def auto_migrate(delay_push = false)
          remote "cd #{config.current_path}"
          remote "padrino rake dm:auto:migrate -e #{config.env}"
          push! unless delay_push
        end

        def restart(delay_push = false)
          remote "touch #{config.current_path}/tmp/restart.txt"
          push! unless delay_push
        end
      end
    end
  end
end

