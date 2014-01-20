require 'fileutils'
begin
  require 'rainbow'
rescue LoadError
end

# Compare program_1 & program_2 output
# Usage: ruby run.rb program_1 program_2 test_suite_directory

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
  raise UsageException unless ARGV.count == 5
  prog1 = ARGV.shift
  prog2 = ARGV.shift
  suite = ARGV.shift  
  throw UsageException.new unless File.exists?(prog1) && File.exists?(prog2) && Dir.exists?(suite)

  temp_file1, temp_file2 = "", ""
  begin temp_file1 = "#{suite}/#{prog1}_#{rand(1000)}.out" end while File.exists? temp_file1
  begin temp_file2 = "#{suite}/#{prog2}_#{rand(1000)}.out" end while File.exists? temp_file2

  Dir.open(suite).each do |file_name|
    next if ['.', '..', temp_file1, temp_file2].include? file_name
    params = File.read "#{suite}/#{file_name}"
    raise NoTestFileException.new("Couldn't open #{file_name}") if params.nil?

    system "./#{prog1} #{params} > #{temp_file1}"
    system "./#{prog2} #{params} > #{temp_file2}"

    if FileUtils::compare_file temp_file1, temp_file2
      print "#{file_name} PASSED", :green
    else
      print "#{file_name} FAILED", :red
      print "#{temp_file1} : #{temp_file2}", :yellow
      system "diff #{temp_file1} #{temp_file2}"
    end
  end

rescue UsageException => e
  print "Usage: ruby run.rb program_1 program_2 test_suite_directory", :red
  exit
rescue NoTestFileException => e
  print e.message, :red
end

File.delete temp_file1, temp_file2
