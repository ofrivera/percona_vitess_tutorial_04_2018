create table users(
       id bigint not null,
       name VARCHAR(128) not null,
       email VARCHAR(128) not null,
       UNIQUE KEY `email_idx` (email),
       PRIMARY KEY(id)
);

create table feeds(
       id bigint not null,
       user_id bigint not null,
       description varchar(256) not null default "",
       created_at bigint not null,
       updated_at bigint not null,
       primary key(id)
);

create table feed_items(
       id bigint not null,
       feed_id bigint not null,
       feed_type char(4) not null,
       created_at bigint not null,
       payload text not null,
       primary key(feed_id, id)
);
