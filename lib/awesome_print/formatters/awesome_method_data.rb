require File.dirname(__FILE__) + "/format_options"

class AwesomeMethodData

  def initialize(method)
    @method_object = method
  end

  def method_name
    @method_object.name.to_s
  end

  def argument_list
    if @method_object
      if @method_object.respond_to?(:parameters) # Ruby 1.9.2+
                                                 # See http://ruby.runpaint.org/methods#method-objects-parameters
        args = @method_object.parameters.inject([]) do |arr, (type, name)|
          name ||= (type == :block ? 'block' : "arg#{arr.size + 1}")
          arr << case type
                   when :req        then name.to_s
                   when :opt, :rest then "*#{name}"
                   when :block      then "&#{name}"
                   else '?'
                 end
        end
      else # See http://ruby-doc.org/core/classes/Method.html#M001902
        args = (1..@method_object.arity.abs).map { |i| "arg#{i}" }
        args[-1] = "*#{args[-1]}" if @method_object.arity < 0
      end

      "(#{args.join(', ')})"
    else
      '(?)'
    end
  end

  def owner

    # method.to_s formats to handle:
    #
    # #<Method: Fixnum#zero?>
    # #<Method: Fixnum(Integer)#years>
    # #<Method: User(#<Module:0x00000103207c00>)#_username>
    # #<Method: User(id: integer, username: string).table_name>
    # #<Method: User(id: integer, username: string)(ActiveRecord::Base).current>
    # #<UnboundMethod: Hello#world>
    #

    if @method_object
      if @method_object.to_s =~ /(Unbound)*Method: (.*)[#\.]/
        unbound, klass = $1 && '(unbound)', $2
        if klass && klass =~ /(\(\w+:\s.*?\))/  # Is this ActiveRecord-style class?
          klass.sub!($1, '')                    # Yes, strip the fields leaving class name only.
        end
        result = "#{klass}#{unbound}".gsub('(', ' (')
      end
      result.to_s
    else
      '?'
    end
  end

  def print
    "#{$format_options.colorize(owner, :class)}##{$format_options.colorize(method_name, :method)}#{$format_options.colorize(argument_list, :args)}"
  end
end