### Instructions


## Application with Mysql 
1) Set docker-compose env variables to point to proper mysql host in `docker-compose.yml`.

2) Run the following command:
```
docker-compose up 
```
3) Start one client writer:
```
docker-compose exec app /bin/bash -c 'ruby cli/feed_creator.rb'
```

4) Notice that previous command created two users and it's adding items to their feeds. Copy feed ids from output and then use it as paramater in the following command. 


5) Start a client that follows to a single feed_id:
  ```
  docker-compose exec app /bin/bash -c 'ruby cli/client.rb FEED_ID'
  ```
## Application with Vitess Unsharded


1) Now, we the vitess cluster set up pointed to your original db, set up Vitess to be an unsharded cluster.

```
./lvtctl.sh ApplyVschema -vschema_file $HOME/sandboxes/activity_feed/demo_app/schemas/vschema_unsharded.json  test_keyspace
```

2) Update the app to point now to the Vitess cluster


3) Notice that everything works as before, but now the application is behind Vitess


## Application with Vitess Sharded


1) Create vschemas for the tables and change the cluster to be sharded:


```
./lvtctl.sh ApplyVschema -vschema_file $HOME/sandboxes/activity_feed/demo_app/schemas/vschema_sharded.json  test_keyspace
```


2) Success your application is now sharded (with a single shard) with Vitess in front of it. But is it always that easy?

## Caveats some queries would not work.


1) Go to vitess console and notice what happens with this query: 

```
select * from feed_items order by created_at desc;
```

It is not supported in vitess.

2) Show client failing when using that endpoint.

Notice that the client that was subscribed to two feeds ids now it's getting errors.

3) Show how to fix it and then run the app again.

4) Stop the app and change docker-compose.yml `VITESS_READY_QUERIES` env variable to be yes.

8) Start everything again. Start the writers and clients again:
```
docker-compose exec -e FEED_ID=7,8 app /bin/bash -c 'ruby cli/client.rb'  # Use Same feed id as first writer from previous run
docker-compose exec app /bin/bash -c 'ruby cli/client.rb 7,8'
```

## Resharding


