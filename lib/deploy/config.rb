module Deploy
  class Config
    class << self
      attr_accessor :env
      attr_accessor :user_name
      attr_accessor :remote
    end
  end
end
