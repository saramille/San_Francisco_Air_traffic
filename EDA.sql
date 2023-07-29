--About this dataset
--This dataset contains information on air traffic passenger statistics by the airline. 
--It includes information on the airlines, airports, and regions that the flights departed 
--from and arrived at. It also includes information on the type of activity, price category,
--terminal, boarding area, and number of passengers.

--Display the first five rows of the airtraffic data

SELECT * FROM airtraffic limit 5;


--1. Change the activity period into date format e.g. to_date('05 Dec 2000', 'DD Mon YYYY')
Create table airtraffic_1 as(
SELECT *, to_date(activity_period::text, 'YYYYMM') as new_date
from airtraffic);

select * from airtraffic_1;

--replace operating airline 'United Airlines-Pre 07/01/2013' with just 'United Airlines'
Update airtraffic_1
set operating_airline=replace(operating_airline,'United Airlines-Pre 07/01/2013','United Airlines')
;
select * from airtraffic_1;


---1. what are the top 5 airlines with the highest number of passengers?
Create view top_5_airlines_bypassengercount as(
select operating_airline, sum(adjusted_passenger_count) as total_passenger_count
from airtraffic_1
group by operating_airline
order by sum(adjusted_passenger_count) desc
)
--"United Airlines - Pre 07/01/2013"	106333323
--"United Airlines"						 64961880
--"SkyWest Airlines"					 35711773
--"American Airlines"					 34588714
--"Virgin America"						 26934738

;

--2. What are the top five flight locations? 
Create view top_5_flight_locations as(
select geo_region, sum(adjusted_passenger_count) as total_passenger_count
	from airtraffic_1
	group by geo_region
	order by sum(adjusted_passenger_count) desc
)--"US"	   339042637
--"Asia"	44213493
--"Europe"	26695446
--"Canada"	13901776
--"Mexico"	 8084752
;

--3. What is the total number of passengers aggregated per year, per month, 
-----  o (Which month has the highest flights? and which has the lowest?)

-----3a total number of passengers aggregated per year
Drop view if exists passenger_count_per_year;
create view passenger_count_per_year as (
select year,sum(adjusted_passenger_count) as total_passengers
from airtraffic_1
group by year
order by year
)
--order by sum(adjusted_passenger_count) desc --highest being year 2015 with 500,670,094 passengers
											--lowest 2006 with 11,431,198 passengers

;
-----3b total number of passengers aggregated per month
Drop view if exists passenger_count_per_month;
create view passenger_count_per_month as (
select year,extract (month from new_date) as mon, sum(adjusted_passenger_count) as total_passengers
from airtraffic_1
group by year, mon
order by year,mon
)
--order by sum(adjusted_passenger_count) desc --highest being 07/2015 with 4,802,431 passengers, 
											--lowest 02/2006 with 2,247,255 passengers

;

--4. Total number of domestic and international flight
Drop view if exists total_domestic_international_flights;
create view total_domestic_international_flights as (
select geo_summary, sum(adjusted_passenger_count) as total_passengers
from airtraffic_1
group by geo_summary
)
--"Domestic"	    339,042,637
--"International"	101,141,443

;
-----4a Which month, on average, has the highest/lowest domestic (international) flight?
Drop view if exists monthly_avg_domestic_international_flights;
create view monthly_avg_domestic_international_flights as (
select geo_summary, extract(month from new_date) as mon, month, round(avg(adjusted_passenger_count),0) as avg_passengers
from airtraffic_1
group by geo_summary, mon, month
order by geo_summary, avg_passengers desc
)
--Highest: "Domestic"	7	"July"	65,662 
--Lowest:  "Domestic"	2	"February"	49,414
--Highest: "International"	8	"August"	12,623
--Lowest: "International"	2	"February"	8,966
;

--5. Total number of outgoing, incoming and transit flights
Drop view if exists total_outgoing_incoming_transit_flights;
create view total_outgoing_incoming_transit_flights as (
select adjusted_activity_type_code, sum(adjusted_passenger_count) as total_passengers
from airtraffic_1
group by adjusted_activity_type_code
)
--"Thru / Transit * 2"	2,743,160
--"Deplaned (outgoing)"		  218,967,525
--"Enplaned (incoming)"	      218,473,395

;

-----5a. What is the top 5 destinations (per passenger count)?
Drop view if exists top_5_outgoing_flights;
create view top_5_outgoing_flights as (
select adjusted_activity_type_code, geo_region,sum(adjusted_passenger_count) as total_passengers
from airtraffic_1
where adjusted_activity_type_code='Enplaned'
group by adjusted_activity_type_code,geo_region
order by total_passengers desc
)
--"Enplaned"	"US"	   168,641,265
--"Enplaned"	"Asia"	    21,595,706
--"Enplaned"	"Europe"	13,250,422
--"Enplaned"	"Canada"	 6,945,383
--"Enplaned"	"Mexico"	 4,032,019

;
---  5b. Where are the top 5 incoming flights from?
Drop view if exists top_5_incoming_flights;
create view top_5_incoming_flights as (
select adjusted_activity_type_code, geo_region,sum(adjusted_passenger_count) as total_passengers
from airtraffic_1
where adjusted_activity_type_code='Deplaned'
group by adjusted_activity_type_code,geo_region
order by total_passengers desc
	)
--"Deplaned"	"US"	   168,598,100
--"Deplaned"	"Asia"	    22,136,341
--"Deplaned"	"Europe"	13,347,248
--"Deplaned"	"Canada"	 6,883,159
--"Deplaned"	"Mexico"	 3,880,403
;
--6. Which terminal serves the highest number of passengers, 
--and what are the top terminals with the highest passenger count?

Drop view if exists top_5_terminals;
create view top_5_terminals as (
select terminal, sum(adjusted_passenger_count) as total_passengers
from airtraffic_1
group by terminal
order by total_passengers desc
--"Terminal 3"	180,112,752
--"International"	115,769,799
--"Terminal 1"	110,241,078
--"Terminal 2"	 34,060,240
--"Other"				211
)
;
--7. What percentage of the flightes were low fare?

select distinct (price_category_code)
from airtraffic_1;

--"Low Fare"
--"Other"
--two price categories. Now calculating the % of low fare customers
select price_category_code, count(price_category_code), 
count(*)* 100/(select count(*) from airtraffic_1) as percent_low_fare
from airtraffic_1
group by price_category_code;












Drop table if exists price_category;
create table price_category as (
select price_category_code, sum(adjusted_passenger_count) as total_passenger
from airtraffic_1
group by price_category_code
)
;
select * from price_category;

select price_category_code, total_passenger*100/(sum(total_passenger(*)) over ()) as percent_low_fare
from price_category
group by price_category_code;

select price_category_code, total_passenger, total_passenger/sum(total_passenger)*100 as percent_passengers
from price_category
group by price_category_code,total_passenger
;

select price_category_code, total_passenger/sum(total_passenger)
from price_category
group by ;

select (select sum(adjusted_passenger_count) from airtraffic_1 where price_category_code='Low Fare') /(select sum(adjusted_passenger_count)from airtraffic_1)*100 as percent_low_fare
from airtraffic_1;