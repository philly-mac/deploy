module Deploy
  module Recipes
    class RailsDataMapper < ::Deploy::Recipes::Base

      self.actions = [:get_and_pack_code, :push_code, :unpack, :link, :bundle, :clean_up, :restart]

      class << self

        def setup
           create_directories
        end

        def deploy_create
          run_actions({:after => :bundle, :actions => [:setup_db, :auto_migrate]})
        end

        def deploy
          run_actions({:after => :bundle, :actions => :auto_upgrade})
        end

        def create_directories
          mkdir "#{Config.get(:shared_path)}/log"
          mkdir "#{Config.get(:shared_path)}/config"
          mkdir "#{Config.get(:shared_path)}/vendor"
          mkdir "#{Config.get(:shared_path)}/tmp"
          mkdir "#{Config.get(:releases_path)}"
          remote "echo \"rvm --create use default\" > #{Config.get(:app_root)}/.rvmrc"
        end

        def get_and_pack_code
          run_now! "cd #{Config.get(:local_root)}"
          run_now! "git pull origin master"
          run_now! "tar --exclude='.git' --exclude='log' --exclude='vendor/ruby' -cjf /tmp/#{Config.get(:app_name)}.tar.bz2 *"
        end

        def push_code
          cmd = "rsync "
          cmd << Config.get(:extra_rsync_options) unless !Config.get(:extra_rsync_options)
          cmd << "/tmp/#{Config.get(:app_name)}.tar.bz2 #{Config.get(:username)}@#{Config.get(:remote)}:/tmp/"
          run_now! cmd
        end

        def setup_db
          remote "cd #{Config.get(:current_path)}"
          remote "bundle exec rake db:create RAILS_ENV=#{Config.get(:env)}"
        end

        def unpack
          release_stamp = Time.now.strftime('%Y%m%d%H%M%S')
          file_exists "/tmp/#{Config.get(:app_name)}.tar.bz2",
            [
              "cd #{Config.get(:releases_path)}",
              "mkdir #{release_stamp}",
              "cd #{release_stamp}",
              "tar -xjf /tmp/#{Config.get(:app_name)}.tar.bz2",
            ]
            remote "chown -Rf #{Config.get(:remote_user)}:#{Config.get(:remote_group)} #{Config.get(:app_root)}"
            remote "find #{Config.get(:current_path)} -type d -exec chmod 775 '{}' \\;"
            remote "find #{Config.get(:current_path)} -type f -exec chmod 664 '{}' \\;"
            remote "find #{Config.get(:shared_path)}/vendor -type d -name \"bin\" -exec chmod -Rf 775 '{}' \\;"
        end

        def link
          remote "for i in $( ls -rl -m1 #{Config.get(:releases_path)} ); do LATEST_RELEASE=$i; break; done"

          link_exists(Config.get(:current_path), [ "rm #{Config.get(:current_path)}" ])
          link_not_exists("#{Config.get(:releases_path)}/$LATEST_RELEASE", ["ln -s #{Config.get(:releases_path)}/$LATEST_RELEASE #{Config.get(:current_path)}"])
          link_not_exists("#{Config.get(:shared_path)}/log", ["ln -s #{Config.get(:shared_path)}/log #{Config.get(:releases_path)}/$LATEST_RELEASE/log"])
          link_not_exists("#{Config.get(:shared_path)}/vendor", ["ln -s #{Config.get(:shared_path)}/vendor #{Config.get(:releases_path)}/$LATEST_RELEASE/vendor"])
          link_not_exists("#{Config.get(:shared_path)}/tmp", ["ln -s #{Config.get(:shared_path)}/tmp #{Config.get(:releases_path)}/$LATEST_RELEASE/tmp"])
        end

        def bundle
          remote "source /usr/local/lib/rvm"
          remote "rvm rvmrc trust #{Config.get(:app_root)}"
          remote "cd #{Config.get(:current_path)}"
          remote "bundle install --without test development --deployment"
        end

        def clean_up
          remote "cd #{Config.get(:releases_path)}"
          remote "export NUM_RELEASES=`ls -trl -m1 | wc -l`"
          remote "export NUM_TO_REMOVE=$(( $NUM_RELEASES - #{Config.get(:max_num_releases)} ))"
          remote "export COUNTER=1"
          on_good_exit "[[ $NUM_TO_REMOVE =~ ^[0-9]+$ ]] && [[ $COUNTER =~ ^[0-9]+$ ]] && [[ $NUM_TO_REMOVE -ge 1 ]]",
            [
              "for i in $( ls -tlr -m1 ); do echo \"removing $i\"; rm -rf $i; [[ $COUNTER == $NUM_TO_REMOVE ]] && break; COUNTER=$(( $COUNTER + 1 )); done",
            ]
        end

        def auto_upgrade
          remote "cd #{Config.get(:current_path)}"
          remote "bundle exec rake db:autoupgrade RAILS_ENV=#{Config.get(:env)}"
        end

        def auto_migrate
          remote "cd #{Config.get(:current_path)}"
          remote "bundle exec rake db:automigrate RAILS_ENV=#{Config.get(:env)}"
        end

        def restart
          remote "touch #{Config.get(:current_path)}/tmp/restart.txt"
        end

      end
    end
  end
end

