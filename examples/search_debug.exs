alias ElixirDrip.Storage.Search, as: S
require Flow

users = S.users()

pretty_users = users \
|> Flow.from_enumerable() \
|> Flow.map(&S.set_full_name(&1)) \
|> Flow.map(&S.set_country(&1)) \
|> Flow.map(&S.set_preferences(&1))

all_media = 100 \
            |> S.random_media(length(users)) \
            |> Flow.from_enumerable()

chp_media = S.custom_hash_partition_media() \
            |> Flow.from_enumerable(max_demand: 1) \
            |> Flow.partition() \
            |> Flow.reduce(fn -> %{} end, \
                           fn media, accum -> \
                             Map.update(accum, media.user_id, 1, &(&1 + 1)) \
                           end) \
           |> Enum.to_list()
           # WRONG result: [{2, 1}, {3, 1}, {1, 1}, {3, 2}, {4, 1}]

chp_media = S.custom_hash_partition_media() \
            |> Flow.from_enumerable(max_demand: 1) \
            |> Flow.partition(hash: fn m -> {m, m.user_id} end) \
            |> Flow.reduce(fn -> %{} end, \
                           fn media, accum -> \
                             Map.update(accum, media.user_id, 1, &(&1 + 1)) \
                           end) \
           |> Enum.to_list()
           # WRONG result: [{2, 1}, {1, 1}, {3, 3}]

# partitions, given by the last element of the tuple,
# are 0-index based, thus the -1
chp_media = S.custom_hash_partition_media() \
            |> Flow.from_enumerable(max_demand: 1) \
            |> Flow.partition(hash: fn m -> {m, m.user_id-1} end) \
            |> Flow.reduce(fn -> %{} end, \
                           fn media, accum -> \
                             Map.update(accum, media.user_id, 1, &(&1 + 1)) \
                           end) \
           |> Enum.to_list()
           # RIGHT RESULT: [{1, 1}, {2, 1}, {4, 1}, {3, 3}]

chp_media = S.custom_hash_partition_media() \
            |> Flow.from_enumerable(max_demand: 1) \
            |> Flow.partition(key: {:key, :user_id}) \
            |> Flow.reduce(fn -> %{} end, \
                           fn media, accum -> \
                             Map.update(accum, media.user_id, 1, &(&1 + 1)) \
                           end) \
           |> Enum.to_list()
           # RIGHT RESULT: [{1, 1}, {2, 1}, {4, 1}, {3, 3}]

chp_size_media = S.custom_hash_partition_media() \
            |> Flow.from_enumerable(max_demand: 1) \
            |> Flow.partition(key: {:key, :user_id}) \
            |> Flow.reduce(fn -> %{} end, \
                           fn %{user_id: user_id, file_size: size}, accum -> \
                             Map.update(accum, user_id, size, &(&1 + size)) \
                           end)
           # RIGHT RESULT: [{2, 2725}, {1, 9817}, {3, 15920}, {4, 9301}]

flow = Flow.bounded_join(:inner, \
        pretty_users, \
        chp_size_media, \
        &(&1.id), \
        &(elem(&1, 0)), \
        fn user, {_user_id, total_size} -> {user.full_name, total_size} end) \
      |> Enum.sort(&(elem(&1, 1) >= elem(&2, 1)))
      # RIGHT RESULT: [{"Jose Valim", 13139}, {"Andre Albuquerque", 9236}, {"Daniel Caixinha", 9225},
      #  {"Joe Armstrong", 9076}]

flow = Flow.bounded_join(:left_outer, \
        pretty_users, \
        chp_size_media, \
        &(&1.id), \
        &(elem(&1, 0)), \
        fn user, right_elem ->
          case right_elem do
            nil                    -> {user.full_name, 0}
            {_user_id, total_size} -> {user.full_name, total_size}
          end
        end) \
      |> Enum.sort(&(elem(&1, 1) >= elem(&2, 1)))
      # RIGHT RESULT: [{"Jose Valim", 13139}, {"Andre Albuquerque", 9236}, {"Daniel Caixinha", 9225},
      #  {"Joe Armstrong", 9076}, {"Mike Williams", 0}, {"Atenas", 0},
      #   {"Robert Virding", 0}, {"Jose Lusquinos", 0}, {"Billy Boy", 0}]

