#top 5 most active makers by number of trades
select maker, total_trades, round(total_volume, 2) as total_volume
from maker
order by total_trades desc
limit 5;
