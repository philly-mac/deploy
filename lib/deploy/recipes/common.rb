module Deploy
  module Recipes
    module Common

      def setup
        self.actions = [:create_directories]
        run_actions
      end

      def deploy_create
        self.actions = [
          :get_and_pack_code,
          :push_code,
          :get_release_tag,
          :link,
          :unpack,
          :bundle,
          :setup_db,
          :auto_migrate,
          :clean_up,
          :restart
        ]
        run_actions
      end

      def deploy
        self.actions = [
          :get_and_pack_code,
          :push_code,
          :get_release_tag,
          :link,
          :unpack,
          :bundle,
          :auto_upgrade,
          :clean_up,
          :restart
        ]
        run_actions
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
        run_now! "tar --exclude='.git' --exclude='log' --exclude='tmp' --exclude='vendor/ruby' -cjf /tmp/#{Config.get(:app_name)}.tar.bz2 *"
      end

      def push_code
        cmd = "rsync "
        cmd << Config.get(:extra_rsync_options) unless !Config.get(:extra_rsync_options)
        cmd << "/tmp/#{Config.get(:app_name)}.tar.bz2 #{Config.get(:username)}@#{Config.get(:remote)}:/tmp/"
        run_now! cmd
      end

      def get_release_tag
        Config.set "release_tag", Time.now.strftime('%Y%m%d%H%M%S')
      end

      def unpack
        file_exists "/tmp/#{Config.get(:app_name)}.tar.bz2",
          [
            "cd #{Config.get(:releases_path)}/#{Config.get("release_tag")}",
            "tar -xjf /tmp/#{Config.get(:app_name)}.tar.bz2",
          ]
        remote "find #{Config.get(:current_path)} -type d -exec chmod 775 '{}' \\;"
        remote "find #{Config.get(:current_path)} -type f -exec chmod 664 '{}' \\;"
        remote "chown -Rf #{Config.get(:remote_user)}:#{Config.get(:remote_group)} #{Config.get(:app_root)}"
      end

      def link
        link_exists(Config.get(:current_path), [ "rm #{Config.get(:current_path)}" ])
        remote "mkdir #{Config.get(:releases_path)}/#{Config.get("release_tag")}"
        remote "ln -s #{Config.get(:releases_path)}/#{Config.get("release_tag")} #{Config.get(:current_path)}"
        remote "ln -s #{Config.get(:shared_path)}/log #{Config.get(:current_path)}/log"
        remote "ln -s #{Config.get(:shared_path)}/vendor #{Config.get(:current_path)}/vendor"
        remote "ln -s #{Config.get(:shared_path)}/tmp #{Config.get(:current_path)}/tmp"
      end

      def bundle
        remote "rvm rvmrc trust #{Config.get(:app_root)}"
        remote "cd #{Config.get(:current_path)}"
        remote "bundle install --without test development --deployment"
        remote "find #{Config.get(:shared_path)}/vendor -type d -name \"bin\" -exec chmod -Rf 775 '{}' \\;"
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

      def restart
        remote "touch #{Config.get(:current_path)}/tmp/restart.txt"
      end
    end
  end
end