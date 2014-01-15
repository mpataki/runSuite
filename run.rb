require 'fileutils'

# Test prog1 against prog2 from input found in suite file
# Usage: ruby runSuite_v2.rb ./p1 ./p2 suite

# MAIN

prog1 = ARGV.shift
prog2 = ARGV.shift
suite = ARGV.shift  
unless File.exists?(prog1) && File.exists?(prog2) && Dir.exists?(suite)
  puts "Usage: ruby runSuite_v2.rb program_1 program_2 test_suite_directory"
  exit
end

temp_file1 = "#{prog1}.out"
temp_file2 = "#{prog2}.out"

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
