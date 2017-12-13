require 'junoser/input'
require 'junoser/display/config_store'
require 'junoser/parser'
require 'junoser/transformer'

module Junoser
  module Display
    class Delete
      def initialize(io_or_string)
        @input = io_or_string
      end
      def apply
        sd = Junoser::Input.new(@input).read.split("\n")
        d = sd.grep(/^delete /).map {|l| l.sub(/^delete /, 'set ')}
        s = sd.grep(/^set /)
        set_struct = Junoser::Display::Structure.new(s.join("\n")).transform
        set_h = struct_to_hash(set_struct)
        d.each do |delete_line|
          begin
            delete_line_struct = Junoser::Display::Structure.new(delete_line).transform
            delete_line_hash = struct_to_hash(delete_line_struct)
            set_h = apply_delete(set_h,delete_line_hash)
          rescue
            next
          end
        end

        set_struct = hash_to_struct(set_h)
        Junoser::Display::Set.new(set_struct).transform
      end

      private

      def struct_to_hash(struct)
        struct.gsub!(/\n/, '')
        hash = struct_to_first_hash(struct)
        hash_value_to_hash(hash)
      end

      def hash_value_to_hash(hash)
        hash.each do |key,value|
          if value != {}
            hash.store(key,struct_to_first_hash(value))
            hash_value_to_hash(hash[key])
          end
        end
      end

      def struct_to_first_hash(struct)
        hash = {}
        key,value = "",""
        state = 0
        struct.strip!
        struct.chars.each do |c|
          case state
            when 0 then # initial state
              case c
                when "{" then
                  state += 1 # 1
                when ";" then
                  hash.store(key.strip,value.strip)
                  key,value = "",""
                else
                  key << c
              end
            when 1 then
              case c
                when "{" then
                  value << c
                  state += 1 # 2
                when "}" then
                  hash.store(key.strip,value.strip)
                  key,value = "",""
                  state -= 1 # 0
                else
                  value << c
              end
            else
              case c
                when "{" then
                  value << c
                  state += 1
                when "}" then
                  value << c
                  state -= 1
                else
                  value << c
              end
          end
        end
        hash
      end

      def apply_delete(set_hash,delete_line_hash)
        key,hash = ret_first_key_and_value(delete_line_hash)
        if hash == {}
          set_hash.delete(key)
          set_hash
        else
          apply_delete(set_hash[key],hash)
        end
        set_hash
      end

      def hash_to_struct(hash)
        struct = ""
        hash_to_struct_iter(hash){|str| struct << str}
        struct
      end

      def hash_to_struct_iter(hash,&block)
        hash.each_with_index do |(key,value),i|
          yield key
          if value != {}
            yield "{\n"
            hash_to_struct_iter(value,&block)
          else
            yield ";\n"
          end
          if i == hash.length - 1
            yield "}\n"
          end
        end
      end

      def ret_first_key_and_value(hash)
        hash.each do |key,hash|
          return key,hash
        end
      end
    end
  end
end