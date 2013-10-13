require 'rubygems'
require 'ripper'

module Gnostic
  class VimComplete

    def self.find_start
      VIM::command("let g:gnostic_complete_start_column = #{start_position}" )
    end

    def self.start_position
      window = VIM::Window.current 
      row, col = window.cursor
      buf = window.buffer

      upto_cursor = buf[row][0..col]
      after_cursor = buf[row][(col+1)..-1]

      if after_cursor =~ /^\w/
        #if the next character is a word, then no completions for now
        -1
      elsif upto_cursor =~ /\W(\w+)$/ 
        # if before the cursor there are word characters, we will replace them.
        col - upto_cursor.scan(/\W(\w+)$/).first.first.length
      else
        col
      end
    end

    def self.assemble_buffer_with_splice(splice)
      window = VIM::Window.current 
      row, col = window.cursor
      buf = window.buffer

      buffer_contents = ""
      buf.count.times do |lineno|
        next if lineno == 0
        if row == lineno
          spliced = buf[lineno]
          spliced = spliced.insert(col, splice) + "\n"
          buffer_contents += spliced
        else
          buffer_contents += (buf[lineno]+"\n")
        end
      end
      buffer_contents
    end

    def self.get_parse_tree_with_splice(splice)
      buffer = assemble_buffer_with_splice(splice) 
      parsed_buffer = Ripper.sexp_raw(buffer)

      if parsed_buffer.nil? && splice.empty?
        buffer = assemble_buffer_with_splice("__gnostic__") 
        parsed_buffer = Ripper.sexp_raw(buffer)
      end         

      print "parsed_buffer is nil? #{parsed_buffer.nil?}"
      if parsed_buffer.nil?
        nil
      else
        Gnostic::ParseNode.build_tree(parsed_buffer)
      end
    end


    def self.get_completions(base)
      window = VIM::Window.current
      row, col = window.cursor

      parse_tree = get_parse_tree_with_splice(base)

      if parse_tree
        node = parse_tree.get_node_from_character(row, col)
        outp = "{'word': 'word', 'item': 'item', 'kind':'f', 'menu' : 'menu', 'abbr': 'abbr', 'info': '#{parse_tree.get_context_of_line(row).inspect}'}"
        outp += ",{'word': 'word2', 'item': 'item2', 'kind':'v', 'info': 'this is the other info window'}"
      else
        # the buffer doesnt parse.  do nothing for now.
        outp = ""
      end
      VIM::command("call extend(g:gnostic_complete_completions, [#{outp}])" )

    end

    def self.get_methods_for_variable(v)
      print "I would go and autocomplete #{v}"
    end
  end
end

module Gnostic
  class NodeCollector

    def add(node)
      @nodes ||= []
      @nodes << node

      @lines ||= Hash.new{|h1, k1| h1[k1] = Hash.new{|h2, k2| h2[k2] = []}}

      if node.line && node.col
        @lines[node.line][node.col] = node
      end
    end

    def get_node_from_character(line, column)
      m = get_nodes_on_line(line)
      index = m.keys.reject{|n| n > column}.max 
      index = m.keys.max unless index
      @lines[line][index] if index
    end

    def get_nodes_on_line(line)
      @lines[line]
    end

    def get_context_of_line(line)
      current_node = get_nodes_on_line(line).values.first
      context = []
      while !current_node.nil?
        if [:def].include?(current_node.value)
          name = current_node.children.first.children.first.value
          context << [current_node.value, name]
        elsif [:defs].include?(current_node.value)
          name = current_node.children[2].children[0].value
          context << [current_node.value, name]
        elsif [:module, :class].include?(current_node.value)
          name = current_node.children.first.children.first.children.first.value
          context << [current_node.value, name]
        end
        current_node = current_node.parent
      end
      context
    end
  end

  class ParseNode
    attr_accessor :line, :col, :parent, :children, :value


    def initialize(array, collector, parent = nil)
      @line = nil
      @col = nil
      @parent = parent
      @children = []
      

      if array.is_a?(Array)
        @value = array.shift
        array.each do |c|
          if c.is_a?(Array) && c.size == 2 && c[0].is_a?(Integer) && c[1].is_a?(Integer)
            @line = c[0]
            @col = c[1]
          else
            n = ParseNode.new(c, collector, self)
            children << n
            collector.add(n)
          end
        end
      else
        @value = array
      end
    end

    def self.build_tree(array)
      collector = NodeCollector.new
      node = ParseNode.new(array, collector)
      collector.add(node)
      collector
    end
  end
end


test_code = <<-RUBY
module Fruit
  class Apple
    def self.banana
      puts "you word said foo"
      foo = A.word.bar.f
    end
  end
end
RUBY
##
#require 'pp'
#parsed_buffer = Ripper.sexp_raw(test_code)
#pp parsed_buffer
##
#tree = Gnostic::ParseNode.build_tree(parsed_buffer)
##pp tree.get_context_of_line(4)
##
