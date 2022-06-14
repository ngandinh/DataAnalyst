/* Back up TNHousing table */
select *
into TNHousing2 
from TNHousing

select * from TNHousing2

/* Update column name */
exec sp_rename  'TNHousing2.UniqueID ', 'UniqueID', 'COLUMN'

/* Update Column data type */
alter table TNHousing2 alter column UniqueID int  not null
alter table TNHousing2 alter column YearBuilt int
alter table TNHousing2 alter column Acreage float
alter table TNHousing2 alter column Bedrooms float
alter table TNHousing2 alter column FullBath float
alter table TNHousing2 alter column HalfBath float
alter table TNHousing2 alter column LandValue float
alter table TNHousing2 alter column BuildingValue float
alter table TNHousing2 alter column TotalValue float

/* Add primary key */
alter table TNHousing2
add primary key (UniqueID)

/* Update values N to No, y to Yes for SoldAsVacant column*/
update TNHousing2
set SoldAsVacant = 
	case
		when SoldASVacant = 'N' Then 'No'
		when SoldASVacant = 'Y' then 'Yes'
		else SoldASVacant
	end
/* Find duplicate rows */
with cte as (
select DENSE_RANK() OVER (
						   PARTITION BY    [parcelID]
										  ,[SoldAsVacant]
										  ,[PropertyAddress]
										  ,[OwnerAddress]
										  ,[OwnerName]
										  ,[YearBuilt]
										  ,[Acreage]
										  ,[TotalValue]
										  ,[SaleDate]
										  ,[SalePrice]
										  ,[LegalReference]
							ORDER BY [UniqueID]) Rank,
		*
from [dbo].[TNHousing2] )
select * from cte where rank > 1

/* Remove duplicate rows */
with cte as (
select DENSE_RANK() OVER (
						   PARTITION BY    [parcelID]
										  ,[SoldAsVacant]
										  ,[PropertyAddress]
										  ,[OwnerAddress]
										  ,[OwnerName]
										  ,[YearBuilt]
										  ,[Acreage]
										  ,[TotalValue]
										  ,[SaleDate]
										  ,[SalePrice]
										  ,[LegalReference]
							ORDER BY [UniqueID] )Rank,
		*
from [dbo].[TNHousing2] )
delete from cte where rank > 1

/*
find values missing is PropertAdress 
that have different UniqueID but same ParcelID 
*/
select a.parcelID, a.propertyAddress, b.parcelID, b.propertyAddress
from TNHousing2 a
join TNHousing2 b
on a.parcelID = b.parcelID and a.uniqueID <> b.uniqueID
and a.PropertyAddress is null

/* Update missing PropertyAddress */
update a
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from TNHousing2 a
join TNHousing2 b
on a.parcelID = b.parcelID and a.uniqueID <> b.uniqueID
and a.PropertyAddress is null

/* Add new colums for address, city, and state */
alter table TNHousing2 Add  PropAddress nvarchar(255)
alter table TNHousing2 Add PropCity nvarchar(255)
alter table TNHousing2 Add PropState nvarchar(20)

/* Use parseName to split state, city, and address
propertyAddress(address-2,city-1)
ownerAddress(address-3,city-2,state-1)
*/
update TNHousing2
set PropState = 
	case
		when owneraddress is null then ''
		else PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
	end 
update TNHousing2
set	PropCity =
	case
		when owneraddress is not null
		then PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
		else PARSENAME(REPLACE(propertyaddress, ',', '.') , 1)
	end
update TNHousing2
set	PropAddress =
	case
		when owneraddress is not null
		then PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
		else PARSENAME(REPLACE(propertyaddress, ',', '.') , 2)
	end

/* Drop not needed columns */
alter table TNHousing2
drop column propertyaddress, owneraddress

/* Update NULL with default values for later calculation */
update TNHousing2
set [YearBuilt] = 0
where [YearBuilt] is null
update TNHousing2
set [Acreage] = 0
where [Acreage] is null
update TNHousing2
set [Bedrooms] = 0
where [Bedrooms] is null
update TNHousing2
set [FullBath] = 0
where [FullBath] is null
update TNHousing2
set [HalfBath] = 0
where [HalfBath] is null
update TNHousing2
set [LandValue] = 0
where [LandValue] is null
update TNHousing2
set [BuildingValue] = 0
where [BuildingValue] is null
update TNHousing2
set [TotalValue] = 0
where [TotalValue] is null

/* Update totalValue when totalValue = 0 */
update TNHousing2
set [TotalValue] =  round(saleprice*
		(select avg(totalvalue)/avg(saleprice) 
		from tnhousing2 
		where [TotalValue] <> 0 ),0) 
from tnhousing2
where [TotalValue] = 0 

/* ANALYZE DATA */
/* 1 - Breakdown Number of House Sold each year */
/* Stacked bar chart */
alter view vw_NumberOfHousesSoldByYear as
with houseSold_cte as (
select  count(uniqueID) TotalHouseSold, cast('2013' as int) YearSold
from tnhousing2 
where convert(date,saledate) between '2013-01-01' and '2013-12-31'
union
select count(uniqueID) TotalHouseSold,  cast('2014' as int) YearSold
from tnhousing2
where convert(date,saledate) between '2014-01-01' and '2014-12-31'
union
select  count(uniqueID) TotalHouseSold,  cast('2015' as int) YearSold
from tnhousing2 
where convert(date,saledate) between '2015-01-01' and '2015-12-31'
union
select count(uniqueID) TotalHouseSold,  cast('2016' as int) YearSold
from tnhousing2
where convert(date,saledate) between '2016-01-01' and '2016-12-31'
union
select  count(uniqueID) TotalHouseSold,  cast('2017' as int)  YearSold
from tnhousing2 
where convert(date,saledate) between '2017-01-01' and '2017-12-31'
union
select count(uniqueID) TotalHouseSold,  cast('2018' as int) YearSold
from tnhousing2
where convert(date,saledate) between '2018-01-01' and '2018-12-31'
union
select  count(uniqueID) TotalHouseSold,  cast('2019' as int) YearSold
from tnhousing2 
where convert(date,saledate) between '2019-01-01' and '2019-12-31'
)
 select TotalHouseSold, YearSold  from houseSold_cte


/* 2 - Summary Total for KPI */
alter view vw_SummaryTotal as
select  
		isnull(count(uniqueID),0) NumberofHousesSold,
		isnull(sum(totalvalue),0) cost, 
		isnull(sum(saleprice),0) revenue, 
		isnull(sum(saleprice) - sum(totalvalue),0) totalProfit,
		round(((isnull(sum(saleprice),0)-isnull(sum(totalvalue),0))/
		isnull(sum(totalvalue),0))*100,2) totalProfitPercentage,
		isnull(round((sum(saleprice) - sum(totalvalue))/7,0),0) profitByYear,
		7 year
from TNHousing2


/* 3 - Summary Total by City - Map */
create view vw_SummaryTotalByCity as
select  propcity,
		isnull(count(uniqueID),0) NumberofHousesSold,
		isnull(sum(totalvalue),0) cost, 
		isnull(sum(saleprice),0) revenue, 
		isnull(sum(saleprice) - sum(totalvalue),0) totalProfit,
		isnull(round((sum(saleprice) - sum(totalvalue))/7,0),0) profitByYear,
		'7' year
from TNHousing2
group by propcity

/* 4 - Summary Breakdown by year and city - 3d bar chart */
create view vw_SummaryTotalByCityByYear as
select  propcity, 
		isnull(count(uniqueID),0) NumberofHousesSold,
		isnull(sum(totalvalue),0) cost, 
		isnull(sum(saleprice),0) revenue, 
		isnull(sum(saleprice) - sum(totalvalue),0) totalProfit,
		isnull(round((sum(saleprice) - sum(totalvalue))/7,0),0) profitByYear,
		'2013' year
from TNHousing2 
where convert(date,saledate) between '2013-01-01' and '2013-12-31'
group by propcity
union
select  propcity, 
		isnull(count(uniqueID),0) NumberofHousesSold,
		isnull(sum(totalvalue),0) cost, 
		isnull(sum(saleprice),0) revenue, 
		isnull(sum(saleprice) - sum(totalvalue),0) totalProfit,
		isnull(round((sum(saleprice) - sum(totalvalue))/7,0),0) profitByYear,
		'2014' year
from TNHousing2
where convert(date,saledate) between '2014-01-01' and '2014-12-31'
group by propcity
union
select	propcity,
		isnull(count(uniqueID),0) NumberofHousesSold,
		isnull(sum(totalvalue),0) cost, 
		isnull(sum(saleprice),0) revenue, 
		isnull(sum(saleprice) - sum(totalvalue),0) totalProfit,
		isnull(round((sum(saleprice) - sum(totalvalue))/7,0),0) profitByYear,
		'2015' year
from TNHousing2
where convert(date,saledate) between '2015-01-01' and '2015-12-31'
group by propcity
union
select	propcity,
		isnull(count(uniqueID),0) NumberofHousesSold,
		isnull(sum(totalvalue),0) cost, 
		isnull(sum(saleprice),0) revenue, 
		isnull(sum(saleprice) - sum(totalvalue),0) totalProfit,
		isnull(round((sum(saleprice) - sum(totalvalue))/7,0),0) profitByYear,
		'2016' year
from TNHousing2
where convert(date,saledate) between '2016-01-01' and '2016-12-31'
group by propcity
union
select	propcity,
		isnull(count(uniqueID),0) NumberofHousesSold,
		isnull(sum(totalvalue),0) cost, 
		isnull(sum(saleprice),0) revenue, 
		isnull(sum(saleprice) - sum(totalvalue),0) totalProfit,
		isnull(round((sum(saleprice) - sum(totalvalue))/7,0),0) profitByYear,
		'2017' year
from TNHousing2
where convert(date,saledate) between '2017-01-01' and '2017-12-31'
group by propcity
union
select	propcity,
		isnull(count(uniqueID),0) NumberofHousesSold,
		isnull(sum(totalvalue),0) cost, 
		isnull(sum(saleprice),0) revenue, 
		isnull(sum(saleprice) - sum(totalvalue),0) totalProfit,
		isnull(round((sum(saleprice) - sum(totalvalue))/7,0),0) profitByYear,
		'2018' year
from TNHousing2
where convert(date,saledate) between '2018-01-01' and '2018-12-31'
group by propcity
union
select	propcity,
		isnull(count(uniqueID),0) NumberofHousesSold,
		isnull(sum(totalvalue),0) cost, 
		isnull(sum(saleprice),0) revenue, 
		isnull(sum(saleprice) - sum(totalvalue),0) totalProfit,
		isnull(round((sum(saleprice) - sum(totalvalue))/7,0),0) profitByYear,
		'2019' year
from TNHousing2
where convert(date,saledate) between '2019-01-01' and '2019-12-31'
group by propcity




 				

