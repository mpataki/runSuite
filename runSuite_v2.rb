# Test prog1 against prog2 from input found in suite file
# Usage: ruby runSuite_v2.rb ./p1 ./p2 suite

# MAIN
begin
  prog1 = ARGV.shift
  prog2 = ARGV.shift
  suite = ARGV.shift  
rescue
  puts "Usage: ruby runSuite_v2.rb ./p1 ./p2 suite"
end

File.open(suite).each_line do |line|
  in_file = File.open(line)
  
  if in_file.nil?
    puts "File #{in_file} not found"
    return -1
  end
  p1_output = `#{prog1} < #{line}`
  p2_output = `#{prog2} < #{line}`

  if p1_output == p2_output
    puts "#{line} PASSED"
  else
    puts "#{line} FAILED"
  end
end