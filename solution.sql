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
declare order_total numeric(10, 2);
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

--------------------------------------------------------------
--------------------------- Task 3 ---------------------------
--------------------------------------------------------------

create or replace procedure add_product_to_order(p_order_id int, p_product_id int, p_quantity int)
language plpgsql
as $$
declare
    product_price numeric(10,2);
    product_quantity int;
begin
    if p_quantity <= 0 then
        raise exception 'Кількість не може бути менше або дорівнювати 0';
    end if;

    if not exists(select 1 from orders o where o.order_id = p_order_id) then
        raise exception 'Замовлення з id=% не існує', p_order_id;
    end if;

    select
        price, stock_quantity
    into product_price, product_quantity
    from products p
    where p.product_id = p_product_id;

    if not found then
        raise exception 'Продукта з id=% не існує', p_product_id;
    end if;

    if p_quantity > product_quantity then
        raise exception 'Продукта з id=% недостатньо на складі', p_product_id;
    end if;

    insert into order_items (order_id, product_id, quantity, price)
    values (p_order_id, p_product_id, p_quantity, p_quantity * product_price);

    update products
    set stock_quantity = stock_quantity - 1
    where product_id = p_product_id;
end;
$$;

call add_product_to_order(1, 1, 2);

--------------------------------------------------------------
--------------------------- Task 4 ---------------------------
--------------------------------------------------------------

create or replace function recalculate_order_total()
returns trigger
language plpgsql
as $$
begin
    if tg_op = 'DELETE' then
        update orders
        set    total_amount = calculate_order_total(old.order_id)
        where  order_id = old.order_id;
    else
        update orders
        set    total_amount = calculate_order_total(new.order_id)
        where  order_id = new.order_id;
    end if;

    return null;
end;
$$;

create or replace trigger trg_recalculate_order_total
after insert or update or delete on order_items
for each row
execute function recalculate_order_total();

--------------------------------------------------------------
--------------------------- Task 5 ---------------------------
--------------------------------------------------------------

create or replace function log_order_created()
returns trigger
language plpgsql
as $$
begin
    insert into order_log (order_id, customer_id, action, log_date)
    values (new.order_id, new.customer_id, 'ORDER_CREATED', now());

    return null;
end;
$$;

create or replace trigger trg_log_order_created
after insert
on orders
for each row
execute function log_order_created();
