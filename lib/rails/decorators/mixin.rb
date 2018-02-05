module Rails
  module Decorators
    module Mixin
      def append_features(base)
        decorators.each { |decorator| decorator.decorates(base) }
      end
    end
  end
end
