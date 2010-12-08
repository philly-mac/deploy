module Deploy
  class RecipeMap
    class << self
      attr_accessor :recipe_map

      def map(clazz_name, aliaz)
        recipe_map ||= {}

        recipe_map[aliaz.to_s] = clazz_name.to_s
      end

      def recipe_clazz(clazz_name_or_aliaz)
        clazz_name_or_aliaz = clazz_name_or_aliaz.to_s
        return recipe_map[clazz_name_or_aliaz] if recipe_map.has_key?(clazz_name_or_aliaz)
        clazz_name_or_aliaz
      end
    end
  end
end

