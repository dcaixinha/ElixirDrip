defmodule ElixirDrip.Storage.Providers.GoogleCloudStorage.Live do
  defmodule GoogleCloud do
    use Arc.Definition
  end

  alias HTTPoison.Response

  @behaviour ElixirDrip.Behaviours.StorageProvider

  require Logger

  def upload(path, content) do
    {:ok, stored_path} = GoogleCloud.store(%{filename: path, binary: content})

    Logger.debug("Uploaded #{inspect(byte_size(content))} bytes to Google Cloud Storage, path: #{stored_path}")

    {:ok, :uploaded}
  end

  def download(path) do
    %Response{
      body: content,
      status_code: 200
    } = GoogleCloud.url({path, %{}}, signed: true)
        |> HTTPoison.get!()

    Logger.debug("Downloaded #{path} (#{byte_size(content)} bytes) from Google Cloud Storage.")

    {:ok, content}
  end
end
