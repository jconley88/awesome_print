require File.dirname(__FILE__) + "/awesome_method_data"

class AwesomeMethod

  def initialize(object, name)
    @name = name
    method_object = getMethodObject(object) if reasonable_name_input?
    @method_data = AwesomeMethodData.new(method_object)
  end

  def method_name
    @name.to_s
  end

  def argument_list
    @method_data.argument_list
  end

  def owner
    @method_data.owner
  end

  private

  def getMethodObject(object)
    if object.respond_to?(@name, true)         # Is this a regular method?
      the_method = object.method(@name) rescue nil     # Avoid potential ArgumentError if object#method is overridden.
      if the_method && the_method.respond_to?(:arity) # Is this original object#method?
        the_method                      # Yes, we are good.
      end
    elsif object.respond_to?(:instance_method)        # Is this an unbound method?
      object.instance_method(@name)
    end
  end

  def reasonable_name_input?
    # Ignore garbage, ex. 42.methods << [ :blah ]
    @name.is_a?(Symbol) || @name.is_a?(String)
  end
end