#!/usr/bin/env ruby
require 'parser/current'

class Parse
  attr_reader :filename, :code, :ast
  def initialize(filename)
    @filename = filename
    @code     = File.read(filename)
    @ast      = Parser::CurrentRuby.parse(@code)
  end

  def find_before_actions
    return recursive_find_before_action(@ast, [])
  end

  def find_method(method_sym)
    return recursive_find_method(@ast, method_sym, [])[0]
  end

  def find_relative_key_on_ast(ast)
    method_name = ast.to_a[0]
    result = recursive_find_relative_key_on_ast(ast, [])
    result.each { |hash| hash[:method] = method_name }
    return result
  end

  private
  def recursive_find_before_action(ast, result)
    if ast.type == :send && ast.to_a[1] == :before_action
      result << ast.to_a[2].to_a[0]
    else
      for child in ast.children
        recursive_find_before_action(child, result) if child && child.instance_of?(Parser::AST::Node)
      end
    end

    return result
  end

  def recursive_find_method(ast, method_sym, result)
    if ast.type == :def && ast.to_a[0] == method_sym
      result << ast
    else
      for child in ast.children
        recursive_find_method(child, method_sym, result) if child && child.instance_of?(Parser::AST::Node)
      end
    end
    return result
  end

  def recursive_find_relative_key_on_ast(ast, result)
    if ast.type == :send && ast.to_a[1] == :t && ast.to_a[2].to_a[0].start_with?('.')
      result << { :line => ast.loc.line, :key => ast.to_a[2].to_a[0], :file => @filename }
    else
      for child in ast.children
        recursive_find_relative_key_on_ast(child, result) if child && child.instance_of?(Parser::AST::Node)
      end
    end

    return result
  end
end

# === command line ===
#
folder_path = ARGV[0]
files = Dir[File.join(folder_path, '**', '*.rb')]

# get all before_actions
all_before_actions = files.map { |file| Parse.new(file).find_before_actions }.flatten.uniq.compact

# find all i18n relative key in these before_actions
all_suspect = files.map do |file|
  p = Parse.new(file)
  matched_methods = all_before_actions.map { |method| p.find_method method }.compact
  result = matched_methods.map do |ast|
    found = p.find_relative_key_on_ast(ast)
    found.empty? ? nil : found
  end.compact
  result.empty? ? nil : result
end.compact.flatten

# Print the outpt
all_suspect.each { |hash| puts "#{hash[:file]}:#{hash[:line]} ##{hash[:method]} - #{hash[:key]}" }
