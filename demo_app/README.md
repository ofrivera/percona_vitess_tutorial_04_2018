### Instructions

1) Set docker-compose env variables to point to proper vitess cluster

2) Run the following command:
```
docker-compose up 
```
3) Start two client writers:
```
docker-compose exec app /bin/bash -c 'ruby cli/client.rb
docker-compose exec app /bin/bash -c 'ruby cli/client.rb
```

4) Notice that previous command created two users and it's adding items to their feeds. Copy feed ids from output and then use it as paramater in the following command. 


5) Start a client that subscribes to a single feed_id:
  ```
  docker-compose exec app /bin/bash -c 'ruby cli/client.rb FEED_ID'
  ```

  Start a second client that subscribes to two feed ids.
  ```
  docker-compose exec app /bin/bash -c 'ruby cli/client.rb FEED_ID_1, FEED_ID_2'
  ```

5) Change the vschema to be sharded

```
./lvtctl.sh ApplyVschema -vschema_file $HOME/sandboxes/activity_feed/demo_app/schemas/vschema_sharded.json  test_keyspace
```

Notice that the client that was subscribed to two feeds ids now it's getting errors.

6) Use vtexplain to show what's the problem with the query. 

7) Stop the app and change docker-compose.yml `DB_ADAPTER` env variable to be vitess

8) Start everything again. Start the writers and clients again:
```
docker-compose exec -e FEED_ID=7 app /bin/bash -c 'ruby cli/client.rb'  # Use same feed id as first writer from previous run
docker-compose exec -e FEED_ID=8 app /bin/bash -c 'ruby cli/client.rb'  # Use Same feed id as first writer from previous run
docker-compose exec app /bin/bash -c 'ruby cli/client.rb 7,8'
docker-compose exec app /bin/bash -c 'ruby cli/client.rb 7'
```

9) Move to resharding.
