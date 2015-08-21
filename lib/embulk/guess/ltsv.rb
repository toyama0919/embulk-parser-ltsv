module Embulk
  module Guess
    class LtsvParserGuessPlugin < LineGuessPlugin
      Plugin.register_guess("ltsv", self)

      def guess_lines(config, sample_lines)
        columns = {}
        sample_lines.each do |line|
          hash = {}
          array = line.split("\t").each { |pair|
            key, value = pair.split(":", 2)
            hash[key] = value
          }

          hash.each do |k, v|
            columns[k] = get_embulk_type(v)
          end
        end
        schema = []
        columns.each do |k,v|
          schema << {'name' => k, 'type' => v}
        end
        guessed = {}
        guessed["type"] = "ltsv"
        guessed["schema"] = schema
        return {"parser" => guessed}
      end

      private

      def get_embulk_type(val)
        if val =~ /^\d+\.\d+$/
          return "double"
        end

        if val =~ /^\d+$/
          return "long"
        end

        begin
          Time.parse(val)
          return "timestamp"
        rescue => e
        end

        if val =~ /^(true|false)$/i
          return "boolean"
        end
        return "string"
      end
    end
  end
end
