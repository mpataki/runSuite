require 'fileutils'
require 'rainbow'

class UsageException < StandardError
end

class NoTestFileException < StandardError
  attr_reader :message

  def initialize(message)
    @message = message
  end
end

# MAIN
begin
  raise UsageException unless ARGV.count == 2
  prog = ARGV.shift
  suite = ARGV.shift
  throw UsageException.new unless File.exists?(prog) && Dir.exists?(suite)

  temp_file = ""
  begin temp_file = "#{suite}/#{prog}_#{rand(1000)}.out" end while File.exists? temp_file

  Dir.open(suite).each do |file_name|
    next if ['.', '..', temp_file].include?(file_name) || file_name.match('.out')

    system "./#{prog} < #{suite}/#{file_name} > #{temp_file}"
    file_name = file_name.slice!(0..file_name.length-4) # cut off '.in'

    if FileUtils::compare_file temp_file, "#{suite}/#{file_name}.out"
      puts Rainbow("#{file_name} PASSED").green
    else
      puts Rainbow("#{file_name} FAILED").red
      puts Rainbow("#{file_name}.out : #{temp_file}").yellow
      system "diff #{suite}/#{file_name}.out #{temp_file}"
    end
  end

rescue UsageException => e
  puts Rainbow("Usage: ruby run.rb program test_suite_directory").red
  exit
rescue NoTestFileException => e
  puts Rainbow(e.message).red
end

File.delete temp_file
