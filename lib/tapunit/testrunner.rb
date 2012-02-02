#--
#
# Author:: Nathaniel Talbott.
# Copyright::
#   * Copyright (c) 2000-2003 Nathaniel Talbott. All rights reserved.
#   * Copyright (c) 2008-2011 Kouhei Sutou <kou@clear-code.com>
# License:: Ruby license.

#require 'test/unit/color-scheme'
require 'test/unit/ui/testrunner'
require 'test/unit/ui/testrunnermediator'
#require 'test/unit/ui/console/outputlevel'

module TapUnit

  # Runs a Test::Unit::TestSuite on the console.
  class TestRunner < Test::Unit::UI::TestRunner

    # Creates a new TestRunner for running the passed
    # suite. If quiet_mode is true, the output while
    # running is limited to progress dots, errors and
    # failures, and the final result. io specifies
    # where runner output should go to; defaults to
    # STDOUT.
    def initialize(suite, options={})
      super

      @output = @options[:output] || STDOUT

      @level = 0

      @already_outputted = false
      @top_level = true

      @counts = Hash.new{ |h,k| h[k] = 0 }
    end

    private
    def change_output_level(level)
      old_output_level = @current_output_level
      @current_output_level = level
      yield
      @current_output_level = old_output_level
    end

    def setup_mediator
      super

      suite_name = @suite.to_s
      suite_name = @suite.name if @suite.kind_of?(Module)


    end

    #def attach_to_mediator
    #  @mediator.add_listener(TestResult::FAULT,            &method(:add_fault))
    #  @mediator.add_listener(TestRunnerMediator::STARTED,  &method(:started))
    #  @mediator.add_listener(TestRunnerMediator::FINISHED, &method(:finished))
    #  @mediator.add_listener(TestCase::STARTED_OBJECT,     &method(:test_started))
    #  @mediator.add_listener(TestCase::FINISHED_OBJECT,    &method(:test_finished))
    #  @mediator.add_listener(TestSuite::STARTED_OBJECT,    &method(:test_suite_started))
    #  @mediator.add_listener(TestSuite::FINISHED_OBJECT,   &method(:test_suite_finished))
    #end

    def attach_to_mediator
      @mediator.add_listener(TestResult::FAULT,            &method(:tapout_fault))
      @mediator.add_listener(TestRunnerMediator::STARTED,  &method(:tapout_before_suite))
      @mediator.add_listener(TestRunnerMediator::FINISHED, &method(:tapout_after_suite))
      @mediator.add_listener(TestCase::STARTED_OBJECT,     &method(:tapout_before_test))
      @mediator.add_listener(TestCase::FINISHED_OBJECT,    &method(:tapout_pass))
      @mediator.add_listener(TestSuite::STARTED_OBJECT,    &method(:tapout_before_case))
      @mediator.add_listener(TestSuite::FINISHED_OBJECT,   &method(:tapout_after_case))
    end


    # TAP-Y/J Revision
    REVISION = 4

    def test_suite_started(suite)
      #if @top_level
      #  @top_level = false
      #  return
      #end

      output_single(indent, nil, VERBOSE)
      if suite.test_case.nil?
        _color = color("suite")
      else
        _color = color("case")
      end
      output_single(suite.name, _color, VERBOSE)
      output(": ", nil, VERBOSE)
      @level += 1
    end

    def test_suite_finished(suite)
      @level -= 1
    end

    #
    # Before everything else.
    #
    def tapout_before_suite(result)
      @result = result
      @suite_start = Time.now

      doc = {
        'type'  => 'suite',
        'start' => @suite_start.strftime('%Y-%m-%d %H:%M:%S'),
        'count' => self.test_count,
        'seed'  => self.options[:seed],
        'rev'   => REVISION
      }
      return doc
    end

    #
    # After everything else.
    #
    def tapout_after_suite(elapsed_time)
      doc = {
        'type' => 'final',
        'time' => elapsed_time, #Time.now - @suite_start,
        'counts' => {
          'total' => @counts[:total],
          'pass'  => @counts[:pass], #self.test_count - self.failures - self.errors - self.skips,
          'fail'  => @counts[:fail],
          'error' => @counts[:error],
          'omit'  => @counts[:omit],
          'todo'  => @counts[:todo], 
        } #,
        #'assertions' => {
        #   'total' => @result.assertion_count + @counts[:fail],
        #   'pass'  => @result.assertion_count,
        #   'fail'  => @counts[:fail]
        #}
      }
      return doc
    end

    #
    #
    #
    def tapout_before_case(testcase)
      doc = {
        'type'    => 'case',
        'subtype' => testcase.test_case.nil? ? 'suite' : nil
        'label'   => testcase.name,
        'level'   => @level
      }

      @level += 1

      return doc
    end

    #
    #
    #
    def tapout_after_case(testcase)
      @level -= 1
    end

    #
    def tapout_before_test(test)
      @test_start = Time.now
    end

    def tapout_fault(fault)
      case fault
      when Test::Unit::Pending
        tapout_todo(fault)
      when Test::Unit::Omission
        tapout_skip(fault)
      when Test::Unit::Notification
        tapout_note(fault)
      when Test::Unit::Failure
        tapout_fail(fault)
      else
        tapout_error(fault)
      end

      #@already_outputted = true if fault.critical?
    end

    #
    def tapout_pass(test)
      @counts[:total] += 1
      @counts[:pass]  += 1

      name = test.name.sub(/\(.+?\)\z/, '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'pass',
        #'setup': foo instance
        'label'       => name
        #'expected' => 2
        #'returned' => 2
        #'file'     => test_file
        #'line'     => test_line
        #'source'   => source(test_file)[test_line-1].strip,
        #'snippet'  => code_snippet(test_file, test_line),
        #'coverage':
        #  file: lib/foo.rb
        #  line: 11..13
        #  code: Foo#*
        'time' => Time.now - @suite_start_time
      }

      stdout, stderr = test_runner.stdout, test_runner.stderr
      doc['stdout'] = stdout unless stdout.empty?
      doc['stderr'] = stderr unless stderr.empty?

      return doc
    end

    #
    def tapout_todo(fault)
      @counts[:total] += 1
      @counts[:todo]  += 1

      file, line = location(fault.location)
      rel_file   = file.sub(Dir.pwd+'/', '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'todo',
        'label'       => fault.test_name,
        #'setup' => "foo instance",
        #'expected' => 2,
        #'returned' => 1,
        #'file'     => test_file
        #'line'     => test_line
        #'source'   => source(test_file)[test_line-1].strip,
        #'snippet'  => code_snippet(test_file, test_line),
        #'coverage' =>
        #  'file' => lib/foo.rb
        #  'line' => 11..13
        #  'code' => Foo#*
        'exception' => {
          'message'   => clean_message(fault.message),
          'class'     => fault.class.name,
          'file'      => rel_file,
          'line'      => line,
          'source'    => source(file)[line-1].strip,
          'snippet'   => code_snippet(file, line),
          'backtrace' => filter_backtrace(fault.location)
        },
        'time' => Time.now - @suite_start
      }
      return doc
    end

    #
    def tapout_skip(fault)
      @counts[:total] += 1
      @counts[:omit]  += 1

      file, line = location(fault.location)
      rel_file   = file.sub(Dir.pwd+'/', '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'skip',
        'label'       => fault.test_name,
        #'setup' => "foo instance",
        #'expected' => 2,
        #'returned' => 1,
        #'file'     => test_file
        #'line'     => test_line
        #'source'   => source(test_file)[test_line-1].strip,
        #'snippet'  => code_snippet(test_file, test_line),
        #'coverage' =>
        #  'file' => lib/foo.rb
        #  'line' => 11..13
        #  'code' => Foo#*
        'exception' => {
          'message'   => clean_message(fault.message),
          'class'     => fault.class.name,
          'file'      => rel_file,
          'line'      => line,
          'source'    => source(file)[line-1].strip,
          'snippet'   => code_snippet(file, line),
          'backtrace' => filter_backtrace(fault.location)
        },
        'time' => Time.now - @suite_start
      }
      return doc
    end

    #
    def tapout_failure(fault)
      @counts[:total] += 1
      @counts[:fail]  += 1

      file, line = location(fault.location)
      rel_file = e_file.sub(Dir.pwd+'/', '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'fail',
        'label'       => fault.test_name,
        #'setup' => "foo instance",
        'expected'    => fault.inspected_expected,
        'returned'    => fault.inspected_actual,
        #'file' => test_file
        #'line' => test_line
        #'source' => ok 1, 2
        #'snippet' =>
        #  - 44: ok 0,0
        #  - 45: ok 1,2
        #  - 46: ok 2,4
        #'coverage' =>
        #  'file' => lib/foo.rb
        #  'line' => 11..13
        #  'code' => Foo#*
        'exception' => {
          'message'   => clean_message(e.message),
          'class'     => e.class.name,
          'file'      => rel_file,
          'line'      => line,
          'source'    => source(file)[line-1].strip,
          'snippet'   => code_snippet(file, line),
          'backtrace' => filter_backtrace(fault.location)
        },
        'time' => Time.now - @suite_start
      }

      # TODO
      #stdout, stderr = test_runner.stdout, test_runner.stderr
      #doc['stdout'] = stdout unless stdout.empty?
      #doc['stderr'] = stderr unless stderr.empty?

      return doc
    end

    #
    def tapout_error(fault)
      @counts[:total] += 1
      @counts[:error] += 1

      file, line = location(fault.location)
      rel_file = e_file.sub(Dir.pwd+'/', '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'error',
        'label'       => fault.test_name,
        #'setup' => "foo instance",
        'expected'    => fault.inspected_expected,
        'returned'    => fault.inspected_actual,
        #'file' => test_file
        #'line' => test_line
        #'source' => ok 1, 2
        #'snippet' =>
        #  - 44: ok 0,0
        #  - 45: ok 1,2
        #  - 46: ok 2,4
        #'coverage' =>
        #  'file' => lib/foo.rb
        #  'line' => 11..13
        #  'code' => Foo#*
        'exception' => {
          'message'   => fault.message,   # user_message ?
          'class'     => fault.class.name,
          'file'      => rel_file,
          'line'      => line,
          'source'    => source(file)[line-1].strip,
          'snippet'   => code_snippet(file, line),
          'backtrace' => filter_backtrace(failt.location)
        },
        'time' => Time.now - @suite_start
      }

      # TODO
      #stdout, stderr = test_runner.stdout, test_runner.stderr
      #doc['stdout'] = stdout unless stdout.empty?
      #doc['stderr'] = stderr unless stderr.empty?

      return doc
    end


=begin
    #
    def output_fault_message(fault)
      if fault.expected.respond_to?(:encoding) and
          fault.actual.respond_to?(:encoding) and
          fault.expected.encoding != fault.actual.encoding
        need_encoding = true
      else
        need_encoding = false
      end
      output(fault.user_message) if fault.user_message
      output_single("<")
      output_single(fault.inspected_expected, color("pass"))
      output_single(">")
      if need_encoding
        output_single("(")
        output_single(fault.expected.encoding.name, color("pass"))
        output_single(")")
      end
      output(" expected but was")
      output_single("<")
      output_single(fault.inspected_actual, color("failure"))
      output_single(">")
      if need_encoding
        output_single("(")
        output_single(fault.actual.encoding.name, color("failure"))
        output_single(")")
      end
      output("")

      from, to = prepare_for_diff(fault.expected, fault.actual)
      if from and to
        from_lines = from.split(/\r?\n/)
        to_lines = to.split(/\r?\n/)
        if need_encoding
          from_lines << ""
          to_lines << ""
          from_lines << "Encoding: #{fault.expected.encoding.name}"
          to_lines << "Encoding: #{fault.actual.encoding.name}"
        end
        differ = ColorizedReadableDiffer.new(from_lines, to_lines, self)
        if differ.need_diff?
          output("")
          output("diff:")
          differ.diff
        end
      end
    end
=end

=begin
    def test_finished(test)
      name = test.name.sub(/\(.+?\)\z/, '')

      #unless @already_outputted
      #  output_progress(".", color("pass"))
      #end
      #already_outputted = false
    end
=end

    # Clean the backtrace of any reference to test framework itself.
    def filter_backtrace(backtrace)
      ## remove backtraces that match any pattern in IGNORE_CALLERS
      trace = backtrace.reject{|b| IGNORE_CALLERS.any?{|i| i=~b}}
      ## remove `:in ...` portion of backtraces
      trace = trace.map do |bt| 
        i = bt.index(':in')
        i ? bt[0...i] :  bt
      end
      ## now apply MiniTest's own filter (note: doesn't work if done first, why?)
      trace = MiniTest::filter_backtrace(trace)
      ## if the backtrace is empty now then revert to the original
      trace = backtrace if trace.empty?
      ## simplify paths to be relative to current workding diectory
      trace = trace.map{ |bt| bt.sub(Dir.pwd+File::SEPARATOR,'') }
      return trace
    end

    # Returns a String of source code.
    def code_snippet(file, line)
      s = []
      if File.file?(file)
        source = source(file)
        radius = 2 # TODO: make customizable (number of surrounding lines to show)
        region = [line - radius, 1].max ..
                 [line + radius, source.length].min

        s = region.map do |n|
          {n => source[n-1].chomp}
        end
      end
      return s
    end

    # Cache source file text. This is only used if the TAP-Y stream
    # doesn not provide a snippet and the test file is locatable.
    def source(file)
      @_source_cache[file] ||= (
        File.readlines(file)
      )
    end

    # Parse source location from caller, caller[0] or an Exception object.
    def parse_source_location(caller)
      case caller
      when Exception
        trace  = caller.backtrace.reject{ |bt| bt =~ INTERNALS }
        caller = trace.first
      when Array
        caller = caller.first
      end
      caller =~ /(.+?):(\d+(?=:|\z))/ or return ""
      source_file, source_line = $1, $2.to_i
      return source_file, source_line
    end

    # Get location of exception.
    def location(backtrace)
      last_before_assertion = ""
      backtrace.reverse_each do |s|
        break if s =~ /in .(assert|refute|flunk|pass|fail|raise|must|wont)/
        last_before_assertion = s
      end
      file, line = last_before_assertion.sub(/:in .*$/, '').split(':')
      line = line.to_i if line
      return file, line
    end

    #
    def clean_message(message)
      message.strip #.gsub(/\s*\n\s*/, "\n")
    end

    def puts(string)
      @output.write(string)
      @output.flush      
    end

  end

  #
  class TapY < TestRunner
    def initialize
      require 'yaml' unless respond_to?(:to_yaml)
      super
    end
    def tapout_before_suites(suites, type)
      puts super(suites, type).to_yaml
    end
    def tapout_before_suite(suite)
      puts super(suite).to_yaml
    end
    def tapout_pass(suite, test, test_runner)
      puts super(suite, test, test_runner).to_yaml
    end
    def tapout_skip(suite, test, test_runner)
      puts super(suite, test, test_runner).to_yaml
    end
    def tapout_failure(suite, test, test_runner)
      puts super(suite, test, test_runner).to_yaml
    end
    def tapout_error(suite, test, test_runner)
      puts super(suite, test, test_runner).to_yaml
    end
    def tapout_after_suites(suites, type)
      puts super(suites, type).to_yaml
      puts "..."
    end
  end

  #
  class TapJ < TestRunner
    def initialize
      require 'json' unless respond_to?(:to_json)
      super
    end
    def tapout_before_suites(suites, type)
      puts super(suites, type).to_json
    end
    def tapout_before_suite(suite)
      puts super(suite).to_json
    end
    def tapout_pass(suite, test, test_runner)
      puts super(suite, test, test_runner).to_json
    end
    def tapout_skip(suite, test, test_runner)
      puts super(suite, test, test_runner).to_json
    end
    def tapout_failure(suite, test, test_runner)
      puts super(suite, test, test_runner).to_json
    end
    def tapout_error(suite, test, test_runner)
      puts super(suite, test, test_runner).to_json
    end
    def tapout_after_suites(suites, type)
      puts super(suites, type).to_json
    end
  end

end

