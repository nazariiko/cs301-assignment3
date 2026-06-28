create table customers (
    customer_id serial primary key,
    full_name varchar(100) not null,
    email varchar(100) unique not null,
    balance numeric(10,2) default 0
);

create table products (
    product_id serial primary key,
    product_name varchar(100) not null,
    price numeric(10,2) not null,
    stock_quantity int not null
);

create table orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    order_date timestamp default current_timestamp,
    total_amount numeric(10,2) default 0
);

create table order_items (
    order_item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int not null,
    price numeric(10,2) not null
);

create table order_log (
    log_id serial primary key,
    order_id int,
    customer_id int,
    action varchar(50),
    log_date timestamp default current_timestamp
);

--------------------------------------------------------------
--------------------------- Task 1 ---------------------------
--------------------------------------------------------------

create or replace function calculate_order_total(p_order_id int)
returns int
language plpgsql
as $$
declare order_total int;
begin
    select
        sum(oi.price * oi.quantity) into order_total
    from order_items oi
    where oi.order_id = p_order_id;

    return order_total;
end;
$$;

select calculate_order_total(1);

--------------------------------------------------------------
--------------------------- Task 2 ---------------------------
--------------------------------------------------------------

create or replace procedure create_order(p_customer_id int)
language plpgsql
as $$
begin
    if exists(select 1 from customers c where c.customer_id = p_customer_id) then
        insert into orders (customer_id, order_date, total_amount)
        values (p_customer_id, now(), 0);
    else
        raise exception 'Клієнта з id=% не існує', p_customer_id;
    end if;
end;
$$;

call create_order(1);
