require 'fileutils'
begin
  require 'rainbow'
rescue LoadError
end

class UsageException < StandardError
end

class NoTestFileException < StandardError
  attr_reader :message

  def initialize(message)
    @message = message
  end
end

def print string, color
  begin
    puts Rainbow(string).color(color)
  rescue NoMethodError
    puts string
  end
end

# MAIN
begin
    # Read arguments
  case ARGV.count
  when 3
    options = ARGV.shift
  when 2
  else throw UsageException
  end
  prog = ARGV.shift
  suite = ARGV.shift
  
  throw UsageException.new unless File.exists?(prog) && File.exists?(suite)

  temp_file = ""
  begin temp_file = "#{suite}/#{prog}_#{rand(1000)}.out" end while File.exists? temp_file

  Dir.open(suite).each do |file_name|
    next if ['.', '..', temp_file].include?(file_name) || file_name.match('.out')

    system "./#{prog} #{options == "-a" ? "" : "<"} #{suite}/#{file_name} > #{temp_file}"

    file_name = file_name.slice!(0..file_name.length-4) # cut off '.in'

    if FileUtils::compare_file temp_file, "#{suite}/#{file_name}.out"
      print "#{file_name} PASSED", :green
    else
      print "#{file_name} FAILED", :red
      print "#{file_name}.out : #{prog} output", :yellow
      system "diff #{suite}/#{file_name}.out #{temp_file}"
    end
  end

rescue UsageException => e
  print "Usage: ruby run.rb program test_suite_directory", :red
  exit
rescue NoTestFileException => e
  print e.message, :red
end

File.delete temp_file
