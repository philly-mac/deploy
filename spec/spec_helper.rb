require "deploy"

puts APP_ROOT
puts VIRTUAL_APP_ROOT

class Bacon::Context
  def not_real_recipes
    ["common.rb", "base.rb"]
  end

  def recipes
    {
      :padrino_data_mapper => [
        :setup, :deploy_create,
        :deploy, :get_and_pack_code,
        :push_code, :get_release_tag,
        :link, :unpack,
        :bundle, :setup_db,
        :auto_migrate, :auto_upgrade,
        :clean_up, :restart,
      ],
      #:pronet =>
      :rails_data_mapper => [
        :setup, :deploy_create,
        :deploy, :get_and_pack_code,
        :push_code, :get_release_tag,
        :link, :unpack,
        :bundle, :setup_db,
        :auto_migrate, :auto_upgrade,
        :clean_up, :restart,
      ]
    }
  end


end

  def config
    Deploy::Config
  end

# Bacon.extend(Bacon.const_get("KnockOutput"))
Bacon.extend(Bacon.const_get("TestUnitOutput"))
Bacon.summary_on_exit

