-- hw3, Yuning Gao
-- 1.List names and sellers of products that are no longer available (quantity=0)
select P.name as productName, M.name as SellerName
from products P
left join sell s on P.pid = s.pid
left join merchants M on s.mid = M.mid
where quantity_available = 0 or quantity_available is null;


-- 2  List names and descriptions of products that are not sold.
select P.name as productName, P.description as productDescription
from products P
left join sell S on P.pid = S.pid
where S.pid is null;

-- 3. How many customers bought SATA drives but not any routers?
select count(c.cid) as peopleBoughtSata
from customers c
join place pl on c.cid = pl.cid
join contain co on pl.oid = co.oid
join products p on co.pid = p.pid
where p.description like  '%SATA%'
and c.cid not in(
    select c.cid
    from customers c
    join place pl on c.cid = pl.cid
    join contain co on pl.oid = co.oid
    join products p on co.pid = p.pid
    where p.category = 'Router'

    );

-- 4. HP has a 20% sale on all its Networking products.
update sell S
join products P on S.pid = P.pid
join merchants M on S.mid = M.mid
set S.price = S.price * 0.8
where M.name = 'HP' AND P.category = 'Networking';


-- 5. What did Uriel Whitney order from Acer? (make sure to at least retrieve product names and prices).
select P.name as productName, S.price as productPrice
from products P
join sell S on P.pid = S.pid
join contain C on P.pid = C.pid
join orders O on C.oid = O.oid
join place Pl on O.oid = Pl.oid
join customers Cu on Pl.cid = Cu.cid
join merchants M on S.mid = M.mid
where Cu.fullname = 'Uriel Whitney' and M.name = 'Acer';


-- 6. List the annual total sales for each company (sort the results along the company and the year attributes).
SELECT YEAR(pl.order_date) AS year, m.name AS company, SUM(s.price) AS total_sales
FROM sell s
JOIN contain co ON s.pid = co.pid
JOIN orders o ON co.oid = o.oid
JOIN place pl ON o.oid = pl.oid
JOIN merchants m ON s.mid = m.mid
GROUP BY YEAR(pl.order_date), m.name
ORDER BY YEAR(pl.order_date), total_sales DESC;


-- 7. Which company had the highest annual revenue and in what year?
SELECT YEAR(pl.order_date) AS year, m.name AS company, SUM(s.price) AS total_sales
FROM sell s
JOIN contain co ON s.pid = co.pid
JOIN orders o ON co.oid = o.oid
JOIN place pl ON o.oid = pl.oid
JOIN merchants m ON s.mid = m.mid
GROUP BY YEAR(pl.order_date), m.name
ORDER BY SUM(s.price) desc limit 1;

-- 8. On average, what was the cheapest shipping method used ever?
select AVG(o.shipping_cost) as avgShippingCost, O.shipping_method as shippingCompany
from orders O
group by o.shipping_method
order by AVG(o.shipping_cost) limit 1;

-- 9. What is the best sold ($) category for each company?
WITH CategorySales AS (
    SELECT m.name AS company, p.category, SUM(s.price) AS total_sales
    FROM sell s
    JOIN contain co ON s.pid = co.pid
    JOIN orders o ON co.oid = o.oid
    JOIN place pl ON o.oid = pl.oid
    JOIN merchants m ON s.mid = m.mid
    JOIN products p ON s.pid = p.pid
    GROUP BY m.name, p.category
    ORDER BY m.name, total_sales DESC
)
SELECT company, category, total_sales
FROM (
    SELECT company, category, total_sales,
           ROW_NUMBER() OVER (PARTITION BY company ORDER BY total_sales DESC) AS rn
    FROM CategorySales
) AS ranked
WHERE rn = 1;

-- 10. For each company find out which customers have spent the most and the least amounts.
WITH CustomerSpending AS (
    SELECT m.name AS company, c.fullname AS customer, SUM(s.price) AS total_spent
    FROM sell s
    JOIN contain co ON s.pid = co.pid
    JOIN orders o ON co.oid = o.oid
    JOIN place pl ON o.oid = pl.oid
    JOIN customers c ON pl.cid = c.cid
    JOIN merchants m ON s.mid = m.mid
    GROUP BY m.name, c.fullname
)
SELECT company, customer, total_spent
FROM (
    SELECT company, customer, total_spent,
           ROW_NUMBER() OVER (PARTITION BY company ORDER BY total_spent DESC) AS rn_highest,
           ROW_NUMBER() OVER (PARTITION BY company ORDER BY total_spent ASC) AS rn_lowest
    FROM CustomerSpending
) AS ranked
WHERE rn_highest = 1 OR rn_lowest = 1;
