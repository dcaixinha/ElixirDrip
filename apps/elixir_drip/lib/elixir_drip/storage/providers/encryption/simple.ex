defmodule ElixirDrip.Storage.Providers.Encryption.Simple do
  @behaviour ElixirDrip.Behaviours.EncryptionProvider

  @encrypted_tag "#encrypted"

  def encrypt(content, _encryption_key),
    do: content <> @encrypted_tag

  def decrypt(content, _encryption_key),
    do: Regex.replace(~r/#{@encrypted_tag}$/, content, "")

  def generate_key(key_length \\ 40) do
    key_length
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
  end
end
