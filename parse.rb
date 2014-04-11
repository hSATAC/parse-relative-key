#!/usr/bin/env ruby
require 'parser/current'

folder_path = ARGV[0]

# == class ==

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
    return recursive_find_relative_key_on_ast(ast, [])
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
      result << { :line => ast.loc.line, :key => ast.to_a[2].to_a[0] }
    else
      for child in ast.children
        recursive_find_relative_key_on_ast(child, result) if child && child.instance_of?(Parser::AST::Node)
      end
    end

    return result
  end
end
