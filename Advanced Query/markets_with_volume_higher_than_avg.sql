#which markets have volume higher than the average volume?
select question, round(volume, 2) as volume
from markets
where volume > (select avg(volume) from markets)
order by volume desc;