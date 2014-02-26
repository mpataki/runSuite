#!/usr/bin/env ruby

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

def print_help
  puts "This is an automated testing suite.

Usage:
  ./run.rb [options] program_1 [program2] suite


program_1 : The executable that is to be tested.
program_2 : The executable that program_1 is to be tested against
suite     : A Directory of test input files.
options   : 
    -a : Passes the content of the input files as arguments to the    
         program(s). Default behaviour is to pass the contents of the 
         files through standard in.

    --help : Show help
    -h     : alias for --help


If two executables are provided, the runSuite will compare their output when 
both are passed each .in file found in the suite directory.

If .out files exist in the suite directory, they will be used instead of the 
second program's output. (This is useful when testing cases where you expect 
your program's output to differ from that of the second program.)

If only one executable is provided then the runSuite expects the suite 
directory to contain both .in and .out files. [file_name].in will be 
passed to the executable and it's output will be compared with
[file_name].out.

`gem install rainbow` to get coloured output. (optional)"

end

def print string, color
  begin
    puts Rainbow(string).color(color)
  rescue NoMethodError
    puts string
  end
end

# Tests the output from a program against a pre-computed directory of .in & .out files.
def Program_vs_Directory args
  prog = args[:prog]
  suite = args[:suite]
  options = args[:options] if args.has_key? :options

  raise NoTestFileException.new("Couldn't find program #{prog}") unless File.exists?(prog)
  raise NoTestFileException.new("Couldn't find test suite #{suite}") unless File.exists?(suite)

  # make a temp file with a name that doesn't already exist
  temp_file = ""
  begin temp_file = "#{suite}/#{prog}_#{rand(1000)}.tmp" end while File.exists? temp_file

  pass_count, fail_count = 0, 0;

  Dir.open(suite).each do |file_name|
    next unless file_name.match('.in') # only use .in files

    if options == "-a"
      params = File.read "#{suite}/#{file_name}"
      raise NoTestFileException.new("Couldn't open #{file_name}") if params.nil?

      `./#{prog} #{params} > #{temp_file} 2>&1`
    else # default behaviour
      `./#{prog} < #{suite}/#{file_name} > #{temp_file} 2>&1`
    end

    # remove extension from file name
    file_name = file_name.slice!(0..file_name.length-4)

    unless File.file?("#{suite}/#{file_name}.out")
      print "#{file_name}.out missing, skipping...", :yellow
      next
    end
    if FileUtils::compare_file temp_file, "#{suite}/#{file_name}.out"
      pass_count += 1
      print "#{file_name} PASSED", :green
    else
      fail_count += 1
      print "#{file_name} FAILED", :red
      print "#{file_name}.out < : > #{prog} output", :yellow
      system "diff #{suite}/#{file_name}.out #{temp_file}"
      puts ""
    end
  end

  puts ""
  print "PASSED: #{pass_count}, FAILED: #{fail_count}", (fail_count > 0) ? :red : :green

  File.delete temp_file
end

def Program_vs_Program args
  prog1 = args[:prog1]
  prog2 = args[:prog2]
  suite = args[:suite]
  options = args[:options] if args.has_key? :options

  raise NoTestFileException.new("Couldn't find program #{prog1}") unless File.exists?(prog1)
  raise NoTestFileException.new("Couldn't find program #{prog2}") unless File.exists?(prog2)
  raise NoTestFileException.new("Couldn't find test suite #{suite}") unless File.exists?(suite)

  temp_file1, temp_file2 = "", ""
  begin temp_file1 = "#{prog1}_#{rand(1000)}.tmp" end while File.exists? temp_file1
  begin temp_file2 = "#{prog2}_#{rand(1000)}.tmp" end while File.exists? temp_file2

  pass_count, fail_count = 0, 0;

  Dir.open(suite).each do |file_name|
    next unless file_name.match('.in') # only use .in files
    output_file = temp_file2
    use_out_file = false

    if File.exists? "#{suite}/#{file_name[0, file_name.length-3]}.out"
      output_file = "#{suite}/#{file_name[0, file_name.length-3]}.out"
      use_out_file = true
    end

    if options == "-a"
      params = File.read "#{suite}/#{file_name}"
      raise NoTestFileException.new("Couldn't open #{file_name}") if params.nil?

      `./#{prog1} #{params} > #{temp_file1} 2>&1`
      `./#{prog2} #{params} > #{temp_file2} 2>&1` unless use_out_file 
    else # default behaviour
      `./#{prog1} < #{suite}/#{file_name} > #{temp_file1} 2>&1`
      `./#{prog2} < #{suite}/#{file_name} > #{temp_file2} 2>&1` unless use_out_file 
    end

    unless File.file?(output_file)
      print "#{output_file} missing, skipping...", :yellow
      next
    end
    if FileUtils::compare_file temp_file1, output_file
      pass_count += 1
      print "#{file_name[0, file_name.length-3]} PASSED", :green
    else
      fail_count += 1
      print "#{file_name[0, file_name.length-3]} FAILED", :red
      print "#{prog1} < : > #{use_out_file ? file_name[0, file_name.length-3] << ".out" : prog2}", :yellow
      system "diff #{temp_file1} #{output_file}"
      puts ""
    end
  end

  puts ""
  print "PASSED: #{pass_count}, FAILED: #{fail_count}", (fail_count > 0) ? :red : :green

    File.delete temp_file1
    File.delete temp_file2 if File.exists? temp_file2   # may not exist if only .out files were used
end


###################### MAIN ######################
begin
    # Read arguments
  options, prog1, last_arg = nil, nil, nil

  case ARGV.count
    when 4
      options = ARGV.shift
    when 3
      options = ARGV.shift
      if File.file?(options)
        prog1 = options
        options = nil
      end
    when 2
    when 1
      print_help if ['-h', '--help'].include? ARGV.shift
      exit
    else raise UsageException
  end

  prog1 = ARGV.shift if prog1.nil? 
  last_arg = ARGV.shift

  if File.directory?(last_arg)
    # Program vs pre-computed output directory
    Program_vs_Directory( {:prog => prog1, 
                           :suite => last_arg, 
                           :options => options
                          })
  else
    # Program vs Program option
    Program_vs_Program( {:prog1 => prog1, 
                         :prog2 => last_arg, 
                         :suite => ARGV.shift, 
                         :options => options 
                        })
  end

rescue Errno::ENOENT
  print "Usage: ./run.rb [options] program_1 [program2] suite", :red
  puts "  Try './run.rb -h' for help"
  exit
rescue UsageException => e
  print "Usage: ./run.rb [options] program_1 [program2] suite", :red
  puts "  Try './run.rb -h' for help"
  exit
rescue NoTestFileException => e
  print e.message, :red
end
