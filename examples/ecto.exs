u = %{username: "ana", password: "qwerasdf", email: "ana@right.there"}
{:ok, user} = ElixirDrip.Accounts.create_user(u)

u = %{username: "jose", password: "qwerasdf", email: "jose@hey.ho"}
{:ok, user} = ElixirDrip.Accounts.create_user(u)

alias ElixirDrip.Repo
alias ElixirDrip.Accounts
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

jose_user = Accounts.get_user_by_username("jose")
jose_owner = Storage.get_owner(jose_user.id)
jose_media = Storage.get_all_media(jose_owner.id)

Storage.store(jose_owner.id, "111.txt", "$/first/folder", "content content 111")
Storage.store(jose_owner.id, "222.txt", "$/second/folder", "content content 222")
Storage.store(jose_owner.id, "333.txt", "$/third/folder", "content content 333")
Storage.store(jose_owner.id, "README.md", "$", "README content")
Storage.store(jose_owner.id, "CHANGELOG.md", "$", "CHANGELOG content")
Storage.store(jose_owner.id, "howto.md", "$/first", "howto content")

Repo.query("select * from media_owners")
Repo.query("select exists(select * from storage_media where full_path = '$' and file_name = 'README.md')")
Repo.query("select RIGHT('#{path}', -#{String.length(pwd)})")
Repo.query("select LENGTH(RIGHT('#{path}', -#{String.length(pwd)}))")

pwd = "$"
pwd = "$/first/folder"
path = "$/first/folder"

Storage.media_by_folder(jose_owner.id, pwd)

last_media = Storage.media_by_folder(jose_owner.id, pwd)[:files] |> Enum.at(-1)
last_media_id = last_media[:id]

Storage.move(jose_owner.id, last_media_id, "$/qaz")
Storage.move(jose_owner.id, readme.id, "$")
Storage.rename(jose_owner.id, readme.id, "README.md")
