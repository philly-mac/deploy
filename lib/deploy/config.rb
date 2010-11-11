module Deploy
  class Config
    attr_accessor :env
    attr_accessor :user_name
    attr_accessor :deploy_root
    attr_accessor :app_name
    attr_accessor :remote
    attr_accessor :current_path
    attr_accessor :shared_path
    attr_accessor :release_path

    def initialize
      set :deploy_root,   "/var/www"
      set :app_name,      "test"
      set_paths!
    end

    def set_paths!
      set :app_root,      "#{self.deploy_root}/#{self.app_name}"
      set :current_path,  "#{self.app_root}/current"
      set :shared_path,   "#{self.app_root}/shared"
      set :releases_path, "#{self.app_root}/releases"
    end

    def config_environment
      load_config("#{VIRTUAL_APP_ROOT}/deploy/environments/#{self.env}.rb")
    end

    def config_custom(file)
      load_config(file)
    end

    def load_config(file)
      if File.exists?(file)
        file_contents = ""
        File.open(file, "r") do |infile|
          while (line = infile.gets)
            file_contents += line
          end
        end
        eval file_contents
      end
      set_paths!
    end

    def refresh!

    end

    def set(key, value)
      self.send("#{key.to_s}=".to_sym, value)
    end

    def method_missing(method_name, *args, &block)
      ::Deploy::Config.send :attr_accessor, method_name.to_s.gsub('=', '').to_sym
      self.send(:"#{method_name}", *args)
    end
  end
end

