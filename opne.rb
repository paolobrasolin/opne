#!/usr/bin/env ruby

require 'readline'
require 'colorize'

module Prompts
  class Prompt
    def initialize(
      question:,
      lead: '',
      regexp: //,
      error: 'Invalid input. Please fix it.'.red
    )
      @question = question
      @lead = lead
      @regexp = regexp
      @error = error
    end

    def ask
      Readline.pre_input_hook = lambda do
        Readline.insert_text @lead
        Readline.redisplay
        Readline.pre_input_hook = nil
      end

      @input = Readline.readline @question, false

      return [@input, parsed] if validates?

      puts @error
      @lead = @input
      ask
    end

    def parsed
      @input
    end

    def validates?
      @input =~ @regexp
    end
  end

  class ListPrompt < Prompt
    def initialize(
      question: "Make your choice\n1\n2\n2\n> ".green,
      lead: '0',
      regexp: /^\d+$/
    )
      super
    end

    def parsed
      @input.to_i
    end
  end
end

SEPARATOR = 'w'

msks = ARGV.take_while { |a| a != SEPARATOR }
cmds = ARGV.drop_while { |a| a != SEPARATOR }[1..-1]

filelist = msks.
             map { |mask| Dir.glob(mask) }.flatten.uniq.
             map { |filename| File.expand_path filename }.sort

if filelist.length == 0
  puts "No file matched.".red
  exit
elsif filelist.length == 1
  final_command = [*cmds, filelist[0]].join(' ')
  puts "Executing: " + final_command.yellow
  system final_command
  exit
end

question = "Choose a file from the list of matches:\n"

filelist.each_with_index do |path, index|
  question << "#{index}) #{path}\n"
end

question << "> "

pro = Prompts::ListPrompt.new question: question.green
pro.ask

if pro.parsed > filelist.length - 1
  puts "Index out of bound.".red
  exit
end

final_command = [*cmds, filelist[pro.parsed]].join(' ')

puts "Executing: " + final_command.yellow
system final_command
