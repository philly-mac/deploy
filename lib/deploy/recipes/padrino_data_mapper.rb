module Deploy
  module Recipes
    class PadrinoDataMapper < ::Deploy::Recipes::Base

      class << self
        def base_deploy(after_spec = nil)
          actions = [:get_and_pack_code, :push_code, :unpack, :link, :bundle, :clean_up, :restart]
          actions.each do |action|
            self.send action
            if after_spec && after_spec[:after] == action
              after_spec[:actions] = [after_spec[:actions]] if !after_spec[:actions].is_a?(Array)
              after_spec[:actions].each{|as_action| self.send(as_action) }
            end
          end
        end
      end

      task :setup do
         create_directories
       end

      task :deploy_create do
        base_deploy({:after => :bundle, :actions => [:setup_db, :auto_migrate]})
      end

      task :deploy do
        base_deploy({:after => :bundle, :actions => :auto_upgrade})
      end

      job :create_directories do
        mkdir "#{config.shared_path}/log"
        mkdir "#{config.shared_path}/config"
        mkdir "#{config.shared_path}/vendor"
        mkdir "#{config.shared_path}/tmp"
        mkdir "#{config.releases_path}"
        remote "echo \"rvm --create use default@#{config.gemset_name}\" > #{config.app_root}/.rvmrc"
      end

      job :get_and_pack_code do
        local "cd #{config.local_root}"
        local "git pull"
        local "tar --exclude='.git' --exclude='log' --exclude='vendor' -cjf /tmp/#{config.app_name}.tar.bz2 *"
      end

      job :push_code do
        cmd = "rsync "
        cmd << config.extra_rsync_options if !config.extra_rsync_options.nil?
        cmd << "/tmp/#{config.app_name}.tar.bz2 #{config.username}@#{config.remote}:/tmp/"
        local cmd
      end

      job :setup_db do
        remote "cd #{config.current_path}"
        remote "bundle exec padrino rake dm:create -e #{config.env}"
      end

      job :unpack do
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
      end

      job :link do
        remote "for i in $( ls -rl -m1 #{config.releases_path} ); do LATEST_RELEASE=$i; break; done"

        link_exists(config.current_path, [ "rm #{config.current_path}" ])
        link_not_exists("#{config.releases_path}/$LATEST_RELEASE", ["ln -s #{config.releases_path}/$LATEST_RELEASE #{config.current_path}"])
        link_not_exists("#{config.shared_path}/log", ["ln -s #{config.shared_path}/log #{config.releases_path}/$LATEST_RELEASE/log"])
        link_not_exists("#{config.shared_path}/vendor", ["ln -s #{config.shared_path}/vendor #{config.releases_path}/$LATEST_RELEASE/vendor"])
        link_not_exists("#{config.shared_path}/tmp", ["ln -s #{config.shared_path}/tmp #{config.releases_path}/$LATEST_RELEASE/tmp"])
      end

      job :bundle do
        remote "source /usr/local/lib/rvm"
        remote "rvm rvmrc trust #{config.app_root}"
        remote "cd #{config.current_path}"
        remote "bundle install --without test development --deployment"
      end

      job :clean_up do
        remote "cd #{config.releases_path}"
        remote "export NUM_RELEASES=`ls -trl -m1 | wc -l`"
        remote "export NUM_TO_REMOVE=$(( $NUM_RELEASES - #{config.max_num_releases} ))"
        remote "export COUNTER=1"
        on_good_exit "[[ $NUM_TO_REMOVE =~ ^[0-9]+$ ]] && [[ $COUNTER =~ ^[0-9]+$ ]] && [[ $NUM_TO_REMOVE -ge 1 ]]",
          [
            "for i in $( ls -tlr -m1 ); do echo \"removing $i\"; rm -rf $i; [[ $COUNTER == $NUM_TO_REMOVE ]] && break; COUNTER=$(( $COUNTER + 1 )); done",
          ]
      end

      job :auto_upgrade do
        remote "cd #{config.current_path}"
        remote "bundle exec padrino rake dm:auto:upgrade -e #{config.env}"
      end

      job :auto_migrate do
        remote "cd #{config.current_path}"
        remote "bundle exec padrino rake dm:auto:migrate -e #{config.env}"
      end

      job :restart do
        remote "touch #{config.current_path}/tmp/restart.txt"
      end

    end
  end
end

