#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-07-09 15:54:55 +0100 (Wed, 09 Jul 2014)
#
#  vim:ts=4:sw=4:et
#
module Rundeck
  module Logging
    def info(string, options = {})
      print formatted_string("[info] #{dated_string(string)}", options) if options[:verbose]
    end

    def debug(string, options = {})
      print formatted_string("[debug] #{dated_string(string)}", options) if options[:debug]
    end

    def notify(string, options = {})
      print formatted_string(string, options)
    end

    def announce(string, options = {})
      print formatted_string(string, { :color => :green, :symbol => "*" }.merge(options))
    end
    alias_method :verbose, :announce

    def warn(string)
      Kernel.warn formatted_string(string, :symbol => "*", :color => :orangae, :newline => false)
    end

    def error(string)
      Kernel.warn formatted_string(string, :symbol => "!", :color => :red, :newline => false)
    end

    def colorise(string, color)
      if options[:colors]
        "\e[#{color_code(color)}m#{string}\e[0m"
      else
        string
      end
    end

    def puts_status(string, state, options = {})
      if state == true
        flag = colorise("   OK   ", :green)
      elsif state == false
        flag = colorise("DISABLED", :red)
      else
        flag = colorise(state, options[:color] || :orange)
      end

      notify(sprintf("%-40s [ %s ]", string, flag))
    end

    private
    def dated_string(string)
      "[#{Time.now}] #{string}"
    end

    def formatted_string(string, options = {})
      symbol = options[:symbol] || " "
      string = string.to_s
      string = colorise(string, options[:color]) if options[:color]
      string << "\n" unless options[:newline] == false
      "  #{symbol} #{string}"
    end

    def color_code(color)
      @colors ||= {
        white: 0,
        dark_grey: 30,
        red: 31,
        green: 32,
        orange: 33,
        cyan: 34,
        purple: 35,
        lightgrey: 36,
        bright_white: 37,
        bold_dark_grey: 90,
        bold_red: 91,
        bold_green: 92,
        yellow: 93,
        bold_cyan: 94,
        bold_purple: 95,
        bold_light_grey: 96,
        bold_bright_white: 97
      }
      @colors[color] || color
    end
  end
end
