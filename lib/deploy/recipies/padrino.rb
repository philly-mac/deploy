module Deploy
  module Recipies
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
          #get_and_pack_code
          release_dir
          unpack
          #bundle
          migrate
          clean_up
          link
          restart
        end

        private

        def create_directories
          mkdir "#{config.shared_path}/log"
          mkdir "#{config.shared_path}/db"
          mkdir "#{config.shared_path}/system"
          mkdir "#{config.shared_path}/config"
          mkdir "#{config.shared_path}/pids", '0770'
          push!
        end

        def get_and_pack_code
          system "cd #{config.local_root}"
          system "git pull"
          system "cd /tmp"
          system "tar --exclude='.git' --exclude='log' -C #{config.local_root} -cjf #{config.app_name} ."
        end

        def setup_db
          on_bad_exit "mysql -u root #{config.database} -e 'show tables;' 2>&1 > /dev/null",
            [
              "cd #{config.current_path}",
              "PADRINO_ENV=#{config.env} bundle exec rake db:setup"
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
          remote "cd #{config.current_path}"
          remote "RAILS_ENV=#{config.env} rake db:migrate"
          push!
        end

        def link
          remote "cd #{config.releases_path}"
          remote "rm #{config.current_path}"
          remote "for i in $( ls -rl -m1 ); do LATEST_RELEASE=$i; break; done"
          remote "ln -s #{config.releases_path}/$LATEST_RELEASE #{config.current_path}"
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

