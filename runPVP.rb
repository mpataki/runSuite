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
  # Read arguments
  case ARGV.count
  when 4
    options = ARGV.shift
  when 3
  else throw UsageException
  end
  prog1 = ARGV.shift
  prog2 = ARGV.shift
  suite = ARGV.shift 
  throw UsageException.new unless File.exists?(prog1) && File.exists?(prog2) && File.exists?(suite)

  temp_file1, temp_file2 = "", ""
  begin temp_file1 = "#{prog1}_#{rand(1000)}.out" end while File.exists? temp_file1
  begin temp_file2 = "#{prog2}_#{rand(1000)}.out" end while File.exists? temp_file2

  Dir.open(suite).each do |file_name|
    next if ['.', '..'].include? file_name

    if options == "-a"
      `./#{prog1} #{suite}/#{file_name} &> #{temp_file1}`
      `./#{prog2} #{suite}/#{file_name} &> #{temp_file2}`
    elsif options == "-i"
        `./#{prog1} #{i} < #{suite}/#{file_name} &> #{temp_file1}`
        `./#{prog2} #{i} < #{suite}/#{file_name} &> #{temp_file2}`
    else # default behaviour
      params = File.read "#{suite}/#{file_name}"
      raise NoTestFileException.new("Couldn't open #{file_name}") if params.nil?

      `./#{prog1} #{params} &> #{temp_file1}`
      `./#{prog2} #{params} &> #{temp_file2}`
    end

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
