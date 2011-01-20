module Deploy
  module Recipes
    class PadrinoDataMapper < ::Deploy::Recipes::Base

      set_base_deploy_actions [:get_and_pack_code, :push_code, :unpack, :link, :bundle, :clean_up, :restart]

      task :setup do
         create_directories
       end

      task :deploy_create do
        base_deploy({:after => :bundle, :actions => [:setup_db, :auto_migrate]})
      end

      task :deploy do
        base_deploy({:after => :bundle, :actions => :auto_upgrade})
      end

      task :create_directories, true do
        mkdir "#{Config.get(:shared_path)}/log"
        mkdir "#{Config.get(:shared_path)}/config"
        mkdir "#{Config.get(:shared_path)}/vendor"
        mkdir "#{Config.get(:shared_path)}/tmp"
        mkdir "#{Config.get(:releases_path)}"
        remote "echo \"rvm --create use default@#{Config.get(:gemset_name)}\" > #{Config.get(:app_root)}/.rvmrc"
      end

      task :get_and_pack_code, true do
        run_now! "cd #{Config.get(:local_root)}"
        run_now! "git pull"
        run_now! "tar --exclude='.git' --exclude='log' --exclude='vendor' -cjf /tmp/#{Config.get(:app_name)}.tar.bz2 *"
      end

      task :push_code, true do
        cmd = "rsync "
        cmd << Config.get(:extra_rsync_options) unless !Config.get(:extra_rsync_options)
        cmd << "/tmp/#{Config.get(:app_name)}.tar.bz2 #{Config.get(:username)}@#{Config.get(:remote)}:/tmp/"
        run_now! cmd
      end

      task :setup_db, true do
        remote "cd #{Config.get(:current_path)}"
        remote "bundle exec padrino rake dm:create -e #{Config.get(:env)}"
      end

      task :unpack, true do
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

      task :link, true do
        remote "for i in $( ls -rl -m1 #{Config.get(:releases_path)} ); do LATEST_RELEASE=$i; break; done"

        link_exists(Config.get(:current_path), [ "rm #{Config.get(:current_path)}" ])
        link_not_exists("#{Config.get(:releases_path)}/$LATEST_RELEASE", ["ln -s #{Config.get(:releases_path)}/$LATEST_RELEASE #{Config.get(:current_path)}"])
        link_not_exists("#{Config.get(:shared_path)}/log", ["ln -s #{Config.get(:shared_path)}/log #{Config.get(:releases_path)}/$LATEST_RELEASE/log"])
        link_not_exists("#{Config.get(:shared_path)}/vendor", ["ln -s #{Config.get(:shared_path)}/vendor #{Config.get(:releases_path)}/$LATEST_RELEASE/vendor"])
        link_not_exists("#{Config.get(:shared_path)}/tmp", ["ln -s #{Config.get(:shared_path)}/tmp #{Config.get(:releases_path)}/$LATEST_RELEASE/tmp"])
      end

      task :bundle, true do
        remote "source /usr/local/lib/rvm"
        remote "rvm rvmrc trust #{Config.get(:app_root)}"
        remote "cd #{Config.get(:current_path)}"
        remote "bundle install --without test development --deployment"
      end

      task :clean_up, true do
        remote "cd #{Config.get(:releases_path)}"
        remote "export NUM_RELEASES=`ls -trl -m1 | wc -l`"
        remote "export NUM_TO_REMOVE=$(( $NUM_RELEASES - #{Config.get(:max_num_releases)} ))"
        remote "export COUNTER=1"
        on_good_exit "[[ $NUM_TO_REMOVE =~ ^[0-9]+$ ]] && [[ $COUNTER =~ ^[0-9]+$ ]] && [[ $NUM_TO_REMOVE -ge 1 ]]",
          [
            "for i in $( ls -tlr -m1 ); do echo \"removing $i\"; rm -rf $i; [[ $COUNTER == $NUM_TO_REMOVE ]] && break; COUNTER=$(( $COUNTER + 1 )); done",
          ]
      end

      task :auto_upgrade, true do
        remote "cd #{Config.get(:current_path)}"
        remote "bundle exec padrino rake dm:auto:upgrade -e #{Config.get(:env)}"
      end

      task :auto_migrate, true do
        remote "cd #{Config.get(:current_path)}"
        remote "bundle exec padrino rake dm:auto:migrate -e #{Config.get(:env)}"
      end

      task :restart, true do
        remote "touch #{Config.get(:current_path)}/tmp/restart.txt"
      end

    end
  end
end

