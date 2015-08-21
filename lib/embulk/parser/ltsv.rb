module Embulk
  module Parser

    class Ltsv < ParserPlugin
      Plugin.register_parser("ltsv", self)

      def self.transaction(config, &control)
        parser_task = config.load_config(Java::LineDecoder::DecoderTask)
        task = {
          "decoder_task" => DataSource.from_java(parser_task.dump),
          "schema" => config.param("schema", :array),
          "null_value_pattern" => config.param("null_value_pattern", :string, default: nil),
          "null_empty_string" => config.param("null_empty_string", :bool, default: false),
          "delimiter" => config.param("delimiter", :string, default: "\t"),
          "label_delimiter" => config.param("label_delimiter", :string, default: ":")
        }
        columns = task["schema"].each_with_index.map do |c, i|
          Column.new(i, c["name"], c["type"].to_sym)
        end
        yield(task, columns)
      end

      def init
        @delimiter = task["delimiter"]
        @label_delimiter = task["label_delimiter"]
        @null_value_pattern = task["null_value_pattern"] ? Regexp.new(task["null_value_pattern"]) : nil
        @null_empty_string = task["null_empty_string"]
        @decoder_task = task.param("decoder_task", :hash).load_task(Java::LineDecoder::DecoderTask)
      end

      def run(file_input)
        decoder = Java::LineDecoder.new(file_input.instance_eval { @java_file_input }, @decoder_task)

        while decoder.nextFile
          while line = decoder.poll
            begin
              array = line.split(@delimiter).map { |pair|
                pair.split(@label_delimiter, 2)
              }
              @page_builder.add(make_record(Hash[*array.flatten]))
            rescue => e
              puts "\n#{e.message}\n#{e.backtrace.join("\n")}"
            end
          end
        end
        page_builder.finish
      end

      private

      def make_record(e)
        @task["schema"].map do |c|
          convert_value(e, c)
        end
      end

      def convert_value(e, c)
        v = convert_value_to_nil(e[c["name"]])
        return nil if v.nil?
        case c["type"]
        when "string"
          v
        when "long"
          v.to_i
        when "double"
          v.to_f
        when "boolean"
          ["yes", "true", "1"].include?(v.downcase)
        when "timestamp"
          if v.empty?
            nil
          else
            c["time_format"] ? Time.strptime(v, c["time_format"]) : Time.parse(v)
          end
        else
          raise "Unsupported type #{c['type']}"
        end
      end

      def convert_value_to_nil(value)
        if value and @null_empty_string
          value = (value == '') ? nil : value
        end
        if value and @null_value_pattern
          value = match_regexp(@null_value_pattern, value) ? nil : value
        end
        value
      end

      def match_regexp(regexp, string)    
        begin    
          return regexp.match(string)    
        rescue ArgumentError => e    
          raise e unless e.message.index("invalid byte sequence in".freeze).zero?    
          log.info "invalid byte sequence is replaced in `#{string}`"    
          string = string.scrub('?')   
          retry    
        end    
        return true    
      end    
    end
  end
end