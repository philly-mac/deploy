module Deploy
  class Config
    attr_accessor :env
    attr_accessor :user_name
    attr_accessor :deploy_root
    attr_accessor :app_root
    attr_accessor :remote
    attr_accessor :current_path
    attr_accessor :shared_path
    attr_accessor :release_path

    def initialize
      set :deploy_root,   "/var/www"
      set :app_root,      "test"
      set :current_path,  "#{self.deploy_root}#{self.app_root}/current"
      set :shared_path,   "#{self.deploy_root}#{self.app_root}/shared"
      set :release_path,  "#{self.deploy_root}#{self.app_root}/releases"
    end

    def environment_config
      file = "#{APP_ROOT}/config/#{self.env}.rb"
      if File.exists?(file)
        file_contents = ""
        File.open(file, "r") do |infile|
          while (line = infile.gets)
            file_contents += line
          end
        end
        eval file_contents
      end
    end

    def set(key, value)
      self.send("#{key.to_s}=".to_sym, value)
    end

    def method_missing(method_name, *args, &block)
      method_name = method_name.to_s.gsub('=','')
      ::Deploy::Config.send :attr_accessor, method_name.to_sym
      self.send(:"#{method_name}=", *args)
    end
  end
end
