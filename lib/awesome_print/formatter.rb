# Copyright (c) 2010-2012 Michael Dvorkin
#
# Awesome Print is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
autoload :CGI, "cgi"
require "shellwords"
require File.dirname(__FILE__) + "/formatters/awesome_method"
require File.dirname(__FILE__) + "/formatters/awesome_method_collection"

module AwesomePrint
  class Formatter

    CORE = [ :array, :hash, :class, :file, :dir, :bigdecimal, :rational, :struct, :method, :unboundmethod ]

    def initialize(inspector)
      @inspector   = inspector
      @options     = inspector.options
    end

    # Main entry point to format an object.
    #------------------------------------------------------------------------------
    def format(object, type = nil)
      core_class = cast(object, type)
      awesome = if core_class != :self
        send(:"awesome_#{core_class}", object) # Core formatters.
      else
        awesome_self(object, type) # Catch all that falls back to object.inspect.
      end
      @options[:html] ? "<pre>#{awesome}</pre>" : awesome
    end

    # Hook this when adding custom formatters. Check out lib/awesome_print/ext
    # directory for custom formatters that ship with awesome_print.
    #------------------------------------------------------------------------------
    def cast(object, type)
      CORE.grep(type)[0] || :self
    end

    private

    # Catch all method to format an arbitrary object.
    #------------------------------------------------------------------------------
    def awesome_self(object, type)
      if @options[:raw] && object.instance_variables.any?
        awesome_object(object)
      else
        $format_options.colorize(object.inspect.to_s, type)
      end
    end

    # Format an array.
    #------------------------------------------------------------------------------
    def awesome_array(a)
      return "[]" if a == []

      if a.instance_variable_defined?('@__awesome_methods__')
        AwesomeMethodCollection.new(a).print
      elsif @options[:multiline]
        width = (a.size - 1).to_s.size 

        data = a.inject([]) do |arr, item|
          index = $format_options.indent
          index << $format_options.colorize("[#{arr.size.to_s.rjust(width)}] ", :array) if @options[:index]
          $format_options.indented do
            arr << (index << @inspector.awesome(item))
          end
        end

        data = $format_options.limited(data, width) if $format_options.should_be_limited?
        "[\n" << data.join(",\n") << "\n#{$format_options.outdent}]"
      else
        "[ " << a.map{ |item| @inspector.awesome(item) }.join(", ") << " ]"
      end
    end

    # Format a hash. If @options[:indent] if negative left align hash keys.
    #------------------------------------------------------------------------------
    def awesome_hash(h)
      return "{}" if h == {}

      keys = @options[:sort_keys] ? h.keys.sort { |a, b| a.to_s <=> b.to_s } : h.keys
      data = keys.map do |key|
        $format_options.plain_single_line do
          [ @inspector.awesome(key), h[key] ]
        end
      end
      
      width = data.map { |key, | key.size }.max || 0
      width += $format_options.indentation if @options[:indent] > 0
  
      data = data.map do |key, value|
        $format_options.indented do
          $format_options.align(key, width) << $format_options.colorize(" => ", :hash) << @inspector.awesome(value)
        end
      end

      data = $format_options.limited(data, width, :hash => true) if $format_options.should_be_limited?
      if @options[:multiline]
        "{\n" << data.join(",\n") << "\n#{$format_options.outdent}}"
      else
        "{ #{data.join(', ')} }"
      end
    end

    # Format an object.
    #------------------------------------------------------------------------------
    def awesome_object(o)
      vars = o.instance_variables.map do |var|
        property = var[1..-1].to_sym
        accessor = if o.respond_to?(:"#{property}=")
          o.respond_to?(property) ? :accessor : :writer
        else
          o.respond_to?(property) ? :reader : nil
        end
        if accessor
          [ "attr_#{accessor} :#{property}", var ]
        else
          [ var.to_s, var ]
        end
      end

      data = vars.sort.map do |declaration, var|
        key = $format_options.left_aligned do
          $format_options.align(declaration, declaration.size)
        end

        unless @options[:plain]
          if key =~ /(@\w+)/
            key.sub!($1, $format_options.colorize($1, :variable))
          else
            key.sub!(/(attr_\w+)\s(\:\w+)/, "#{$format_options.colorize('\\1', :keyword)} #{$format_options.colorize('\\2', :method)}")
          end
        end
        $format_options.indented do
          key << $format_options.colorize(" = ", :hash) + @inspector.awesome(o.instance_variable_get(var))
        end
      end
      if @options[:multiline]
        "#<#{awesome_instance(o)}\n#{data.join(%Q/,\n/)}\n#{$format_options.outdent}>"
      else
        "#<#{awesome_instance(o)} #{data.join(', ')}>"
      end
    end

    # Format a Struct.
    #------------------------------------------------------------------------------
    def awesome_struct(s)
      #
      # The code is slightly uglier because of Ruby 1.8.6 quirks:
      # awesome_hash(Hash[s.members.zip(s.values)]) <-- ArgumentError: odd number of arguments for Hash)
      # awesome_hash(Hash[*s.members.zip(s.values).flatten]) <-- s.members returns strings, not symbols.
      #
      hash = {}
      s.each_pair { |key, value| hash[key] = value }
      awesome_hash(hash)
    end

    # Format Class object.
    #------------------------------------------------------------------------------
    def awesome_class(c)
      if superclass = c.superclass # <-- Assign and test if nil.
        $format_options.colorize("#{c.inspect} < #{superclass}", :class)
      else
        $format_options.colorize(c.inspect, :class)
      end
    end

    # Format File object.
    #------------------------------------------------------------------------------
    def awesome_file(f)
      ls = File.directory?(f) ? `ls -adlF #{f.path.shellescape}` : `ls -alF #{f.path.shellescape}`
      $format_options.colorize(ls.empty? ? f.inspect : "#{f.inspect}\n#{ls.chop}", :file)
    end

    # Format Dir object.
    #------------------------------------------------------------------------------
    def awesome_dir(d)
      ls = `ls -alF #{d.path.shellescape}`
      $format_options.colorize(ls.empty? ? d.inspect : "#{d.inspect}\n#{ls.chop}", :dir)
    end

    # Format BigDecimal object.
    #------------------------------------------------------------------------------
    def awesome_bigdecimal(n)
      $format_options.colorize(n.to_s("F"), :bigdecimal)
    end

    # Format Rational object.
    #------------------------------------------------------------------------------
    def awesome_rational(n)
      $format_options.colorize(n.to_s, :rational)
    end

    # Format a method.
    #------------------------------------------------------------------------------
    def awesome_method(m)
      AwesomeMethodData.new(m).print
    end
    alias :awesome_unboundmethod :awesome_method

    # Format object instance.
    #------------------------------------------------------------------------------
    def awesome_instance(o)
      "#{o.class}:0x%08x" % (o.__id__ * 2)
    end
  end
end
