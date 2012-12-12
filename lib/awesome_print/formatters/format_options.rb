class FormatOptions
  DEFAULT_LIMIT_SIZE = 7

  def initialize(inspector)
    @inspector   = inspector
    @options     = inspector.options
    @indentation = @options[:indent].abs
  end

  def options
    @options
  end

  # Pick the color and apply it to the given string as necessary.
  #------------------------------------------------------------------------------
  def colorize(str, type)
    str = CGI.escapeHTML(str) if @options[:html]
    if @options[:plain] || !@options[:color][type] || !@inspector.colorize?
      str
      #
      # Check if the string color method is defined by awesome_print and accepts
      # html parameter or it has been overriden by some gem such as colorize.
      #
    elsif str.method(@options[:color][type]).arity == -1 # Accepts html parameter.
      str.send(@options[:color][type], @options[:html])
    else
      str = %Q|<kbd style="color:#{@options[:color][type]}">#{str}</kbd>| if @options[:html]
      str.send(@options[:color][type])
    end
  end

  # Utility methods.
  #------------------------------------------------------------------------------
  def align(value, width)
    if @options[:multiline]
      if @options[:indent] > 0
        value.rjust(width)
      elsif @options[:indent] == 0
        indent + value.ljust(width)
      else
        indent[0, @indentation + @options[:indent]] + value.ljust(width)
      end
    else
      value
    end
  end

  def indented
    @indentation += @options[:indent].abs
    yield
  ensure
    @indentation -= @options[:indent].abs
  end

  def left_aligned
    current, @options[:indent] = @options[:indent], 0
    yield
  ensure
    @options[:indent] = current
  end

  def indent
    ' ' * @indentation
  end

  def outdent
    ' ' * (@indentation - @options[:indent].abs)
  end

  # To support limited output, for example:
  #
  # ap ('a'..'z').to_a, :limit => 3
  # [
  #     [ 0] "a",
  #     [ 1] .. [24],
  #     [25] "z"
  # ]
  #
  # ap (1..100).to_a, :limit => true # Default limit is 7.
  # [
  #     [ 0] 1,
  #     [ 1] 2,
  #     [ 2] 3,
  #     [ 3] .. [96],
  #     [97] 98,
  #     [98] 99,
  #     [99] 100
  # ]
  #------------------------------------------------------------------------------
  def should_be_limited?
    @options[:limit] == true or (@options[:limit].is_a?(Fixnum) and @options[:limit] > 0)
  end

  def get_limit_size
    @options[:limit] == true ? DEFAULT_LIMIT_SIZE : @options[:limit]
  end

  def limited(data, width, is_hash = false)
    limit = get_limit_size
    if data.length <= limit
      data
    else
      # Calculate how many elements to be displayed above and below the separator.
      head = limit / 2
      tail = head - (limit - 1) % 2

      # Add the proper elements to the temp array and format the separator.
      temp = data[0, head] + [ nil ] + data[-tail, tail]

      if is_hash
        temp[head] = "#{indent}#{data[head].strip} .. #{data[data.length - tail - 1].strip}"
      else
        temp[head] = "#{indent}[#{head.to_s.rjust(width)}] .. [#{data.length - tail - 1}]"
      end

      temp
    end
  end
end