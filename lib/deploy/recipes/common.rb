module Deploy
  module Recipes
    module Common

      def self.included(base)
        base.class_eval do
          description "setup", "create the directory structure needed for a deployment"
          def setup
            self.class.actions = [:create_directories]
            run_actions(self)
          end

          description "deploy_create", "Deploy the app to the server, and completely wipe the database tables and recreate them"
          def deploy_create
            self.class.actions = [
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
            self.class.run_actions(self)
          end

          description "deploy", "Deploy the app to the server"
          def deploy
            self.class.actions = [
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
            self.class.run_actions(self)
          end

          description "create_directories", "create the directory structure"
          def create_directories
            mkdir "#{Config.get(:shared_path)}/log"
            mkdir "#{Config.get(:shared_path)}/config"
            mkdir "#{Config.get(:shared_path)}/vendor"
            mkdir "#{Config.get(:shared_path)}/tmp"
            mkdir "#{Config.get(:releases_path)}"
            remote "echo \"rvm --create use default\" > #{Config.get(:app_root)}/.rvmrc"
          end

          description "get_and_pack_code", "Makes sure the code is up to date and then tars it up"
          def get_and_pack_code
            run_now! "cd #{Config.get(:local_root)}"
            run_now! "git pull origin master"
            run_now! "tar --exclude='.git' --exclude='log' --exclude='tmp' --exclude='vendor/ruby' -cjf /tmp/#{Config.get(:app_name)}.tar.bz2 *"
          end

          description "push_code", "Pushes the code to the server"
          def push_code
            cmd = "rsync "
            cmd << Config.get(:extra_rsync_options) unless !Config.get(:extra_rsync_options)
            cmd << "/tmp/#{Config.get(:app_name)}.tar.bz2 #{Config.get(:username)}@#{Config.get(:remote)}:/tmp/"
            run_now! cmd
          end

          def get_release_tag
            Config.set "release_tag", Time.now.strftime('%Y%m%d%H%M%S')
          end

          description "unpack", "Unpacks the code to the correct directories"
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

          description "link", "Create the links for which the code can be placed"
          def link
            link_exists(Config.get(:current_path), [ "rm #{Config.get(:current_path)}" ])
            remote "mkdir #{Config.get(:releases_path)}/#{Config.get("release_tag")}"
            remote "ln -s #{Config.get(:releases_path)}/#{Config.get("release_tag")} #{Config.get(:current_path)}"
            remote "ln -s #{Config.get(:shared_path)}/log #{Config.get(:current_path)}/log"
            remote "ln -s #{Config.get(:shared_path)}/vendor #{Config.get(:current_path)}/vendor"
            remote "ln -s #{Config.get(:shared_path)}/tmp #{Config.get(:current_path)}/tmp"
          end

          description "bundle", "Runs bundle to make sure all the required gems are on the ststem"
          def bundle
            remote "rvm rvmrc trust #{Config.get(:app_root)}"
            remote "cd #{Config.get(:current_path)}"
            remote "bundle install --without test development --deployment"
            remote "find #{Config.get(:shared_path)}/vendor -type d -name \"bin\" -exec chmod -Rf 775 '{}' \\;"
          end

          description "clean_up", "Deletes any old releases if there are more than the max configured releases"
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

          description "restart", "Causes the server to restart for this app"
          def restart
            remote "touch #{Config.get(:current_path)}/tmp/restart.txt"
          end
        end
      end

    end
  end
end