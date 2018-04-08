u = %{username: "ana", password: "qwerasdf", email: "ana@right.there"}
{:ok, user} = ElixirDrip.Accounts.create_user(u)

alias ElixirDrip.Repo
alias ElixirDrip.Storage
alias ElixirDrip.Storage.Media
alias ElixirDrip.Storage.Owner
import Ecto.Query

q1 = from u in Owner,
limit: 1

user = Repo.one(q1)

Storage.store(user.id, "test1.txt", "$/this/is/the/full/path", "content content content")

q2 = from m in Media,
order_by: [desc: m.uploaded_at],
limit: 1

media = Repo.one(q2) |> Repo.preload(:owners)

Repo.query("select * from media_owners")
