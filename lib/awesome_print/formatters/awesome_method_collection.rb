class AwesomeMethodCollection

  def initialize(methods)
    object_having_methods = methods.instance_variable_get('@__awesome_methods__')
    @methods = awesomify_methods(methods, object_having_methods)
  end

  def print
    print_array do |result|
      @methods.each_with_index do |item, index|
        result << print_method(index, item)
      end
    end
  end

  private

  def print_method(index, item)
    $format_options.indent + print_index(index) + ' ' + print_name(item.method_name) + print_args(item.argument_list) + ' ' + print_owner(item.owner) + "\n"
  end

  def print_array()
    result = ""
    result << "[\n"
    yield result
    result << "#{$format_options.outdent}]"
  end

  def print_index(index)
    $format_options.options[:index] ? "[#{index.to_s.rjust(max_index_width)}]" : ''
  end

  def print_name(name)
    $format_options.colorize(name.rjust(name_width), :method)
  end

  def print_args(args)
    $format_options.colorize(args.ljust(args_width), :args)
  end

  def print_owner(owner)
    $format_options.colorize(owner, :class)
  end

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