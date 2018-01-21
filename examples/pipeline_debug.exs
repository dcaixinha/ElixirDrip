alias ElixirDrip.Storage,    as: S
alias S.Workers.QueueWorker, as: Q
alias S.Media,               as: M

#download
1..1 |> Enum.each(fn i ->
  m = %M{id: "id#{i}", storage_key: "path/to/#{i}"}
  event = %{media: m, type: :download}

  Q.enqueue Q.Download, event
end)

alias ElixirDrip.Storage,    as: S
alias S.Workers.QueueWorker, as: Q
alias S.Media,               as: M

# upload
1..5 |> Enum.each(fn i ->
  S.store("filename#{i}.txt", "full/path/to/#{i}", "content of #{i}")
end)
