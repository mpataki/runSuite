require 'fileutils'

# Compare program_1 & program_2 output
# Usage: ruby run.rb program_1 program_2 test_suite_directory

# MAIN

prog1 = ARGV.shift
prog2 = ARGV.shift
suite = ARGV.shift  
unless File.exists?(prog1) && File.exists?(prog2) && Dir.exists?(suite)
  puts "Usage: ruby run.rb program_1 program_2 test_suite_directory"
  exit
end

temp_file1, temp_file2 = "", ""
begin temp_file1 = "#{prog1}_#{rand(1000)}.out" end while File.exists? temp_file1
begin temp_file2 = "#{prog2}_#{rand(1000)}.out" end while File.exists? temp_file2

Dir.open(suite).each do |file_name|
  next if ['.', '..', temp_file1, temp_file2].include? file_name
  
  params = File.read("#{suite}/#{file_name}")

  system "./#{prog1} #{params} > #{temp_file1}"
  system "./#{prog2} #{params} > #{temp_file2}"

  if FileUtils::compare_file temp_file1, temp_file2
    puts "#{file_name} PASSED"
  else
    puts "#{file_name} FAILED"
  end
end

File.delete temp_file1, temp_file2
