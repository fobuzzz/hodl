# frozen_string_literal: true

if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'
  
  SimpleCov.start 'rails' do
    add_filter '/spec/'
    add_filter '/config/'
    add_filter '/vendor/'
    add_filter '/bin/'
    
    add_group 'Commands', 'app/commands'
    add_group 'Services', 'app/services'
    add_group 'Controllers', 'app/controllers'
    
    minimum_coverage 90
    
    if ENV['CI']
      formatter SimpleCov::Formatter::SimpleFormatter
    else
      formatter SimpleCov::Formatter::HTMLFormatter
    end
  end
end 