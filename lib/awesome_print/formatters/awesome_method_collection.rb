class AwesomeMethodCollection
  include Enumerable

  def initialize(methods)
    object_having_methods = methods.instance_variable_get('@__awesome_methods__')
    @methods = awesomify_methods(methods, object_having_methods)
  end

  def each
    @methods.each do |m|
      yield m
    end
  end

  def size
    @methods.size
  end

  def out
    data = @methods.inject([]) do |arr, item|
      index = $format_options.indent
      index << "[#{arr.size.to_s.rjust(max_index_width)}]" if $format_options.options[:index]
      $format_options.indented do
        arr << "#{index} #{$format_options.colorize(item.method_name.rjust(name_width), :method)}#{$format_options.colorize(item.argument_list.ljust(args_width), :args)} #{$format_options.colorize(item.owner, :class)}"
      end
    end

    "[\n" << data.join("\n") << "\n#{$format_options.outdent}]"
  end

  private

  def max_index_width
    (@methods.size - 1).to_s.size
  end

  def name_width
    @methods.map { |item| item.method_name.size }.max || 0
  end

  def args_width
    @methods.map { |item| item.argument_list.size }.max || 0
  end

  def awesomify_methods(methods, object)
    methods.sort! { |x, y| x.to_s <=> y.to_s }
    methods.map do |name|
      AwesomeMethod.new(object, name)
    end
  end
end