defmodule ElixirDrip.Behaviours.EncryptionProvider do
  @type encrypted_content :: bitstring()
  @type content :: bitstring()
  @type encryption_key :: binary()
  @type reason :: atom()
  @type key_length :: integer()

  @callback encrypt(content, encryption_key) ::
              encrypted_content
              | {:error, reason}
  @callback decrypt(encrypted_content, encryption_key) ::
              content
              | {:error, reason}
  @callback generate_key(key_length) :: encryption_key
end
