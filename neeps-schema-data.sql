#Easy

#1
select r.id as room_id
from event e, room r
where r.id = e.room and e.id = 'co42010.L01';

#2
select dow as day, tod as time, room
from event
where modle = 'co72010';

#3
select distinct name
from staff s join teaches t on s.id = t.staff, event e
where modle = 'co72010' and t.event = e.id;

#4
select t.staff as staff_number, name, modle as module_number, tod as time
from teaches t join event e on t.event = e.id, staff s
where room = 'cr.132' and dow = 'Wednesday' and s.id = t.staff;

#5
select distinct a.student as student_groups, s.name
from event e join attends a on e.id = a.event, modle m, student s
where e.modle = m.id and s.id = a.student and m.name like '%Database%';



#Medium

#6
select sum(sze) as group_size
from student s join attends a on s.id = a.student, event e
where modle = 'co72010' and a.event = e.id
group by e.id;

#7
select modle as module, name, count(distinct staff) as staff_size
from event e join teaches t on e.id = t.event join modle m on e.modle = m.id
where modle like 'co7%'
group by modle;

#8
select distinct name as module_name
from event e join occurs o on e.id = o.event, modle m
where m.id = modle
group by e.id
having count(*) < 10;

#9
select id
from event
where modle != 'co72010' and tod in (select distinct tod from event where modle = 'co72010');

#10
CREATE VIEW contact_hours
as select staff, sum(duration) as hours
from event e join teaches t on e.id = t.event
group by staff;

select count(staff) as staff_count
from contact_hours
where hours > (select avg(hours) from contact_hours);

DROP VIEW contact_hours;



#Resit

#1
select dow as day, tod as time
from event
where id = 'co72002.L01';

#2
select dow as day, tod as time, room
from event
where modle = 'co72003';

#3
select e.id as event_id
from event e join teaches t on e.id = t.event, staff s
where name = 'Chisholm, Ken' and s.id = t.staff;

#4
select distinct name
from event e join teaches t on e.id = t.event, staff s
where room = 'cr.SMH' and s.id = t.staff;

#5
select sum(duration) as total_hours
from event e join attends a on e.id = a.event and student = 'com.IS.a' join occurs o on e.id = o.event;



#Hard

#11
CREATE VIEW cumming
as select id, dow, duration, CAST(tod as unsigned) as tod
from event e join teaches t on t.event = e.id\
where staff = 'co.ACg';

CREATE VIEW hastie
as select id, dow, duration, CAST(tod as unsigned) as tod
from event e join teaches t on t.event = e.id
where staff = 'co.CHt';

select *
from cumming c, hastie h
where c.dow = h.dow and (c.tod = h.tod or (c.duration = 2 and c.tod = h.tod - 1) or (h.duration = 2 and h.tod = c.tod - 1));

DROP VIEW cumming, hastie;


#12
CREATE VIEW large_rooms
as select id, capacity
from room
where capacity > 60;

CREATE VIEW earliest
as select dow, min(CAST(tod as unsigned)) as first_hour
from event
group by dow;

CREATE VIEW latest
as select dow, max(CAST(tod as unsigned) + duration) as true_last_hour
from event
group by dow;

CREATE VIEW total_hours
as select sum(true_last_hour - first_hour) as tot_hou
from earliest, latest
where earliest.dow = latest.dow;

select lr.id, coalesce(avg(sze)/capacity, 0) /* * 100*/ as occupancy_level, coalesce(sum(duration)/tot_hou, 0) /* * 100*/ as utilization_rate
from large_rooms lr left join event e on lr.id = e.room left join attends a on a.event = e.id left join student s on a.student = s.id, total_hours
group by room;

DROP VIEW large_rooms, earliest, latest, total_hours;

#The commented code serves the purpose of converting the  raw numbers to percentages.
#earliest, latest and total_hours are used to work out the total number of hours that a room can be used for (9 hours for every day except Tuesday which is 12, for a total of 9 * 4 + 12 = 48).
#Room cr.G116+G90 is never used, which is why coalesce() was implemented to replace null values.
#The utilization rate for cr.B1 and cr.SMH is higher than 1 which implies the existence of conflicts.


#13
CREATE VIEW one_hour
as select dow, CAST(tod as unsigned) as tod, count(tod) as ct
from event
where duration = 1 and tod < 17
group by dow;

CREATE VIEW two_hour
as select dow, CAST(tod as unsigned) as tod, 2*count(tod) as ct #events last for two hours
from event
where duration = 2 and tod < 17
group by dow;

CREATE VIEW total
as select oh.dow, oh.ct + th.ct as total
from one_hour oh cross join two_hour th
where oh.dow = th.dow;

CREATE VIEW best_day as
select one_hour.dow, min(total)
from one_hour, total
where one_hour.dow = (select total.dow from total where total.total = (select min(total.total) from total));

CREATE VIEW one_hour_new
as select CAST(tod as unsigned) as tod, count(tod) as ct
from event e, best_day
where duration = 1 and tod < 17 and e.dow = best_day.dow
group by tod; #5, 2, 2, 2, 3, 1, 2 (9, 10, 11, 12, 13, 14, 16)

CREATE VIEW two_hour_new
as select CAST(tod as unsigned) as tod, count(tod) as ct
from event e, best_day
where duration = 2 and tod < 17 and e.dow = best_day.dow
group by tod; #1, 3, 2, 2, 3, 5 (9, 10, 11, 13, 14, 15)

CREATE VIEW two_hour_new_second_hour
as select tod + 1 as tod, ct
from two_hour_new thn; #same as above, only (10, 11, 12, 14, 15, 16)

CREATE VIEW all_hours
as select distinct CAST(tod as unsigned) as tod
from event
where tod > 8 and tod < 17;

CREATE VIEW all_hours_one
as select ah.tod, coalesce(ct, 0) as ct
from all_hours ah left join one_hour_new ohn on ah.tod = ohn.tod;

CREATE VIEW all_hours_one_two
as select aho.tod, aho.ct + coalesce(thn.ct, 0) as ct
from all_hours_one aho left join two_hour_new thn on aho.tod = thn.tod;

CREATE VIEW all_hours_final
as select ahot.tod, ahot.ct + coalesce(thnsh.ct, 0) as ct
from all_hours_one_two ahot left join two_hour_new_second_hour thnsh on ahot.tod = thnsh.tod;

select dow as day, tod as time
from best_day, all_hours_final
where ct = (select min(ct) from all_hours_final);

DROP VIEW one_hour, two_hour, total, best_day, one_hour_new, two_hour_new, two_hour_new_second_hour, all_hours, all_hours_one, all_hours_one_two, all_hours_final;
#It was empirically found that Monday at 09:00 and at 10:00 are just as good as Friday at 12:00; all three instances cancel no more than 4 events.


#15
CREATE VIEW monday_attendee
as select *
from event join attends on id = event
where dow = 'Monday';

CREATE VIEW tuesday_attendee
as select *
from event join attends on id = event
where dow = 'Tuesday';

CREATE VIEW wednesday_attendee
as select *
from event join attends on id = event
where dow = 'Wednesday';

CREATE VIEW thursday_attendee
as select *
from event join attends on id = event
where dow = 'Thursday';

CREATE VIEW friday_attendee
as select *
from event join attends on id = event
where dow = 'Friday';

CREATE VIEW mt_attendee
as select ma.student
from monday_attendee ma join tuesday_attendee tua on ma.student = tua.student;

CREATE VIEW mtw_attendee
as select mta.student
from mt_attendee mta join wednesday_attendee wa on mta.student = wa.student;

CREATE VIEW mtwt_attendee
as select mtwa.student
from mtw_attendee mtwa join thursday_attendee tha on mtwa.student = tha.student;

CREATE VIEW all_attendee
as select distinct mtwta.student
from mtwt_attendee mtwta join friday_attendee fa on mtwta.student = fa.student;

CREATE TABLE sorting_days (
	day_name char(10),
    day_num integer);

insert into sorting_days values ('Monday', 1);
insert into sorting_days values ('Tuesday', 2);
insert into sorting_days values ('Wednesday', 3);
insert into sorting_days values ('Thursday', 4);
insert into sorting_days values ('Friday', 5);

select student as Student_Group, dow as Day, CAST(wkstart + day_num - 1 as DATE) as Date, tod as Time, name Subject, room as Room, duration as Duration
from event e join attends a on a.event = e.id join modle m on modle = m.id join occurs o on o.event = e.id and week = '01' join sorting_days on dow = day_name, week w
where o.event = e.id and o.week = w.id and student in (select student from all_attendee)
order by student, day_num, tod;

DROP VIEW monday_attendee, tuesday_attendee, wednesday_attendee, thursday_attendee, friday_attendee, mt_attendee, mtw_attendee, mtwt_attendee, all_attendee;
DROP TABLE sorting_days;