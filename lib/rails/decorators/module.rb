class Module
  def mixed_into
    @mixed_into ||= []
  end

  # All ancestors of this object that are an extension of
  # +Rails::Decorators::Decorator
  #
  # @return [Array<Module>]
  def decorators
    ancestors.select do |ancestor|
      ancestor.is_a?(Rails::Decorators::Decorator)
    end
  end

  def included(base)
    mixed_into << base
    super if defined? super
  end
end
