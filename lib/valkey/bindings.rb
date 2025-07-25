# frozen_string_literal: true

class Valkey
  module Bindings
    extend FFI::Library

    ffi_lib File.expand_path("./libglide_ffi.so", __dir__)

    class ClientType < FFI::Struct
      layout(
        :tag, :uint # 0 = AsyncClient, 1 = SyncClient
      )
    end

    class ConnectionResponse < FFI::Struct
      layout(
        :conn_ptr, :pointer, # *const c_void
        :connection_error_message, :string # *const c_char (null-terminated C string)
      )
    end

    class CommandError < FFI::Struct
      layout(
        :command_error_message, :string,
        :command_error_type, :int # Assuming RequestErrorType is repr(C) enum
      )
    end

    class CommandResponse < FFI::Struct
      layout(
        :response_type, :int,         # Assuming ResponseType is repr(C) enum
        :int_value, :int64,
        :float_value, :double,
        :bool_value, :bool,
        :string_value, :pointer,      # points to C string
        :string_value_len, :long,
        :array_value, :pointer,       # points to CommandResponse array
        :array_value_len, :long,
        :map_key, :pointer,           # CommandResponse*
        :map_value, :pointer,         # CommandResponse*
        :sets_value, :pointer,        # CommandResponse*
        :sets_value_len, :long
      )
    end

    callback :success_callback, %i[ulong pointer], :void
    callback :failure_callback, %i[ulong string int], :void

    class AsyncClientData < FFI::Struct
      layout(
        :success_callback, :success_callback,
        :failure_callback, :failure_callback
      )
    end

    class ClientData < FFI::Union
      layout(
        :async_client, AsyncClientData
      )
    end

    class CommandResult < FFI::Struct
      layout(
        :response, CommandResponse.by_ref,
        :command_error, CommandError.by_ref
      )
    end

    callback :pubsub_callback, [
      :ulong, # client_ptr
      :int,             # kind (PushKind enum)
      :pointer, :long,  # message + length
      :pointer, :long,  # channel + length
      :pointer, :long   # pattern + length
    ], :void

    attach_function :create_client, [
      :pointer,        # *const u8 (connection_request_bytes)
      :ulong,          # usize (connection_request_len)
      ClientType.by_ref, # *const ClientType
      :pubsub_callback # callback
    ], :pointer        # *const ConnectionResponse

    attach_function :close_client, [
      :pointer # client_adapter_ptr
    ], :void

    attach_function :command, [
      :pointer,     # client_adapter_ptr
      :ulong,       # channel
      :int,         # command_type
      :ulong,       # arg_count
      :pointer,     # args (pointer to usize[])
      :pointer,     # args_len (pointer to c_ulong[])
      :pointer,     # route_bytes
      :ulong        # route_bytes_len
    ], :pointer     # returns *mut CommandResult
  end
end
