module Deploy
  class Config
    attr_accessor :env
    attr_accessor :user_name
    attr_accessor :remote

    def initialize
      self.deploy_root   "/var/www"
      self.app_root      "test"
      self.current_path  "#{self.deploy_root}#{self.app_root}/current"
      self.shared_path   "#{self.deploy_root}#{self.app_root}/shared"
      self.release_path  "#{self.deploy_root}#{self.app_root}/releases"
    end

    def method_missing(method_name, *args, &block)
      ::Deploy::Config.send :attr_accessor, method_name.to_sym
      self.send(:"#{method_name}=", *args)
    end
  end
end
