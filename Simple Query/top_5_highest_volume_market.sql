#Top 5 highest volume markets 
select question, volume
from markets
order by volume desc limit 5;
