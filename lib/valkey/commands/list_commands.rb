# frozen_string_literal: true

class Valkey
  module Commands
    # this module contains commands related to list data type.
    #
    # @see https://valkey.io/commands/#list
    #
    module ListCommands
      # Get the length of a list.
      #
      # @param [String] key
      # @return [Integer]
      def llen(key)
        send_command(RequestType::LLEN, [key])
      end

      # Remove the first/last element in a list, append/prepend it to another list and return it.
      #
      # @param [String] source source key
      # @param [String] destination destination key
      # @param [String, Symbol] where_source from where to remove the element from the source list
      #     e.g. 'LEFT' - from head, 'RIGHT' - from tail
      # @param [String, Symbol] where_destination where to push the element to the source list
      #     e.g. 'LEFT' - to head, 'RIGHT' - to tail
      #
      # @return [nil, String] the element, or nil when the source key does not exist
      #
      # @note This command comes in place of the now deprecated RPOPLPUSH.
      #     Doing LMOVE RIGHT LEFT is equivalent.
      def lmove(source, destination, where_source, where_destination)
        where_source, where_destination = _normalize_move_wheres(where_source, where_destination)

        send_command(RequestType::LMOVE, [source, destination, where_source, where_destination])
      end

      # Remove the first/last element in a list and append/prepend it
      # to another list and return it, or block until one is available.
      #
      # @example With timeout
      #   element = valkey.blmove("foo", "bar", "LEFT", "RIGHT", timeout: 5)
      #     # => nil on timeout
      #     # => "element" on success
      # @example Without timeout
      #   element = valkey.blmove("foo", "bar", "LEFT", "RIGHT")
      #     # => "element"
      #
      # @param [String] source source key
      # @param [String] destination destination key
      # @param [String, Symbol] where_source from where to remove the element from the source list
      #     e.g. 'LEFT' - from head, 'RIGHT' - from tail
      # @param [String, Symbol] where_destination where to push the element to the source list
      #     e.g. 'LEFT' - to head, 'RIGHT' - to tail
      # @param [Hash] options
      #   - `:timeout => [Float, Integer]`: timeout in seconds, defaults to no timeout
      #
      # @return [nil, String] the element, or nil when the source key does not exist or the timeout expired
      #
      def blmove(source, destination, where_source, where_destination, timeout: 0)
        where_source, where_destination = _normalize_move_wheres(where_source, where_destination)

        args = [:blmove, source, destination, where_source, where_destination, timeout]
        send_command(RequestType::BLMOVE, args)
      end

      # Prepend one or more values to a list, creating the list if it doesn't exist
      #
      # @param [String] key
      # @param [String, Array<String>] value string value, or array of string values to push
      # @return [Integer] the length of the list after the push operation
      def lpush(key, value)
        send_command(RequestType::LPUSH, [key, *value])
      end

      # Prepend a value to a list, only if the list exists.
      #
      # @param [String] key
      # @param [String] value
      # @return [Integer] the length of the list after the push operation
      def lpushx(key, value)
        send_command(RequestType::LPUSHX, [key, value])
      end

      # Append one or more values to a list, creating the list if it doesn't exist
      #
      # @param [String] key
      # @param [String, Array<String>] value string value, or array of string values to push
      # @return [Integer] the length of the list after the push operation
      def rpush(key, value)
        value = [value] unless value.is_a?(Array)

        args = [key] + value

        send_command(RequestType::RPUSH, args)
      end

      # Append a value to a list, only if the list exists.
      #
      # @param [String] key
      # @param [String] value
      # @return [Integer] the length of the list after the push operation
      def rpushx(key, value)
        send_command(RequestType::RPUSHX, [key, value])
      end

      # Remove and get the first elements in a list.
      #
      # @param [String] key
      # @param [Integer] count number of elements to remove
      # @return [nil, String, Array<String>] the values of the first elements
      def lpop(key, count = nil)
        args = [key]
        args << Integer(count) if count
        send_command(RequestType::LPOP, args)
      end

      # Remove and get the last elements in a list.
      #
      # @param [String] key
      # @param [Integer] count number of elements to remove
      # @return [nil, String, Array<String>] the values of the last elements
      def rpop(key, count = nil)
        args = [key]
        args << Integer(count) if count
        send_command(RequestType::RPOP, args)
      end

      # Remove the last element in a list, append it to another list and return it.
      #
      # @param [String] source source key
      # @param [String] destination destination key
      # @return [nil, String] the element, or nil when the source key does not exist
      def rpoplpush(source, destination)
        send_command(RequestType::RPOPLPUSH, [source, destination])
      end

      # Remove and get the first element in a list, or block until one is available.
      #
      # @example With timeout
      #   list, element = valkey.blpop("list", :timeout => 5)
      #     # => nil on timeout
      #     # => ["list", "element"] on success
      # @example Without timeout
      #   list, element = valkey.blpop("list")
      #     # => ["list", "element"]
      # @example Blocking pop on multiple lists
      #   list, element = valkey.blpop(["list", "another_list"])
      #     # => ["list", "element"]
      #
      # @param [String, Array<String>] keys one or more keys to perform the
      #   blocking pop on
      # @param [Hash] options
      #   - `:timeout => [Float, Integer]`: timeout in seconds, defaults to no timeout
      #
      # @return [nil, [String, String]]
      #   - `nil` when the operation timed out
      #   - tuple of the list that was popped from and element was popped otherwise
      def blpop(*args)
        _bpop(:blpop, args)
      end

      # Remove and get the last element in a list, or block until one is available.
      #
      # @param [String, Array<String>] keys one or more keys to perform the
      #   blocking pop on
      # @param [Hash] options
      #   - `:timeout => [Float, Integer]`: timeout in seconds, defaults to no timeout
      #
      # @return [nil, [String, String]]
      #   - `nil` when the operation timed out
      #   - tuple of the list that was popped from and element was popped otherwise
      #
      # @see #blpop
      def brpop(*args)
        _bpop(RequestType::BRPOP, args.flatten)
      end

      # Pop a value from a list, push it to another list and return it; or block
      # until one is available.
      #
      # @param [String] source source key
      # @param [String] destination destination key
      # @param [Hash] options
      #   - `:timeout => [Float, Integer]`: timeout in seconds, defaults to no timeout
      #
      # @return [nil, String]
      #   - `nil` when the operation timed out
      #   - the element was popped and pushed otherwise
      def brpoplpush(source, destination, timeout: 0)
        args = [:brpoplpush, source, destination, timeout]
        send_blocking_command(RequestType::BRPOPLPUSH, args, timeout)
      end

      # Pops one or more elements from the first non-empty list key from the list
      # of provided key names. If lists are empty, blocks until timeout has passed.
      #
      # @example Popping a element
      #   valkey.blmpop(1.0, 'list')
      #   #=> ['list', ['a']]
      # @example With count option
      #   valkey.blmpop(1.0, 'list', count: 2)
      #   #=> ['list', ['a', 'b']]
      #
      # @params timeout [Float] a float value specifying the maximum number of seconds to block) elapses.
      #   A timeout of zero can be used to block indefinitely.
      # @params key [String, Array<String>] one or more keys with lists
      # @params modifier [String]
      #  - when `"LEFT"` - the elements popped are those from the left of the list
      #  - when `"RIGHT"` - the elements popped are those from the right of the list
      # @params count [Integer] a number of elements to pop
      #
      # @return [Array<String, Array<String, Float>>] list of popped elements or nil
      def blmpop(timeout, *keys, modifier: "LEFT", count: nil)
        raise ArgumentError, "Pick either LEFT or RIGHT" unless %w[LEFT RIGHT].include?(modifier)

        args = [timeout, keys.size, *keys, modifier]
        args << "COUNT" << Integer(count) if count

        send_command(RequestType::BLMPOP, args)
      end

      # Pops one or more elements from the first non-empty list key from the list
      # of provided key names.
      #
      # @example Popping a element
      #   valkey.lmpop('list')
      #   #=> ['list', ['a']]
      # @example With count option
      #   valkey.lmpop('list', count: 2)
      #   #=> ['list', ['a', 'b']]
      #
      # @params key [String, Array<String>] one or more keys with lists
      # @params modifier [String]
      #  - when `"LEFT"` - the elements popped are those from the left of the list
      #  - when `"RIGHT"` - the elements popped are those from the right of the list
      # @params count [Integer] a number of elements to pop
      #
      # @return [Array<String, Array<String, Float>>] list of popped elements or nil
      def lmpop(*keys, modifier: "LEFT", count: nil)
        raise ArgumentError, "Pick either LEFT or RIGHT" unless %w[LEFT RIGHT].include?(modifier)

        args = [keys.size, *keys, modifier]
        args << "COUNT" << Integer(count) if count

        # pp args

        send_command(RequestType::LMPOP, args)
      end

      # Get an element from a list by its index.
      #
      # @param [String] key
      # @param [Integer] index
      # @return [String]
      def lindex(key, index)
        send_command(RequestType::LINDEX, [key, Integer(index)])
      end

      # Insert an element before or after another element in a list.
      #
      # @param [String] key
      # @param [String, Symbol] where `BEFORE` or `AFTER`
      # @param [String] pivot reference element
      # @param [String] value
      # @return [Integer] length of the list after the insert operation, or `-1`
      #   when the element `pivot` was not found
      def linsert(key, where, pivot, value)
        send_command(RequestType::LINSERT, [key, where, pivot, value])
      end

      # Get a range of elements from a list.
      #
      # @param [String] key
      # @param [Integer] start start index
      # @param [Integer] stop stop index
      # @return [Array<String>]
      def lrange(key, start, stop)
        send_command(RequestType::LRANGE, [key, Integer(start), Integer(stop)])
      end

      # Remove elements from a list.
      #
      # @param [String] key
      # @param [Integer] count number of elements to remove. Use a positive
      #   value to remove the first `count` occurrences of `value`. A negative
      #   value to remove the last `count` occurrences of `value`. Or zero, to
      #   remove all occurrences of `value` from the list.
      # @param [String] value
      # @return [Integer] the number of removed elements
      def lrem(key, count, value)
        send_command(RequestType::LREM, [key, Integer(count), value])
      end

      # Set the value of an element in a list by its index.
      #
      # @param [String] key
      # @param [Integer] index
      # @param [String] value
      # @return [String] `OK`
      def lset(key, index, value)
        send_command(RequestType::LSET, [key, Integer(index), value])
      end

      # Trim a list to the specified range.
      #
      # @param [String] key
      # @param [Integer] start start index
      # @param [Integer] stop stop index
      # @return [String] `OK`
      def ltrim(key, start, stop)
        send_command(RequestType::LTRIM, [key, Integer(start), Integer(stop)])
      end

      private

      def _bpop(cmd, args, &blk)
        timeout = if args.last.is_a?(Hash)
                    options = args.pop
                    options[:timeout]
                  end

        timeout ||= 0
        unless timeout.is_a?(Integer) || timeout.is_a?(Float)
          raise ArgumentError, "timeout must be an Integer or Float, got: #{timeout.class}"
        end

        args.flatten!(1)
        args << timeout
        send_blocking_command(cmd, args, &blk)
      end

      def _normalize_move_wheres(where_source, where_destination)
        where_source      = where_source.to_s.upcase
        where_destination = where_destination.to_s.upcase

        if where_source != "LEFT" && where_source != "RIGHT"
          raise ArgumentError, "where_source must be 'LEFT' or 'RIGHT'"
        end

        if where_destination != "LEFT" && where_destination != "RIGHT"
          raise ArgumentError, "where_destination must be 'LEFT' or 'RIGHT'"
        end

        [where_source, where_destination]
      end
    end
  end
end
