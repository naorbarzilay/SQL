--------------------------------------------Q1-----------------------------------------------------------
select distinct SEC.EmployeeCode
from securityEmployee as SEC
where (select count(distinct CA1.serialNum)
from CheckedAt as CA1 inner join checks as C1 on C1.passengerID=CA1.passengerID and C1.serialNum=CA1.serialNum and C1.checkPointNum=CA1.checkPointNum
where SEC.EmployeeCode=C1.EmployeeCode and datediff(day,CA1.checkDateTime,getdate())<=7)
>= 2* 
(select count(distinct CA1.serialNum)
from CheckedAt as CA1 inner join checks as C1 on C1.passengerID=CA1.passengerID and C1.serialNum=CA1.serialNum and C1.checkPointNum=CA1.checkPointNum
where SEC.EmployeeCode=C1.EmployeeCode and datediff(day,CA1.checkDateTime,getdate()) between 8 and 14
having count(CA1.serialNum)<>0)  -- ���� �� ������� �� 0 �� �� ��� ������� ���� ���� ����

and SEC.finishWorkingDate is null -- ��� ���� �� �� ������� ������� ���� �����

--------------------------------------------Q2-----------------------------------------------------------

select P.passengerID,P.passengerFirstName+' '+ P.passengerLastName as FullName, DATEDIFF(year,P.birthDate,GETDATE()) as Age
from Passenger as P inner join hasTicket as T on P.passengerID=T.passengerID inner join Flight as F on F.flightID=T.flightID inner join Airport as A on A.airportCode=F.toAirportCode
where not exists (select price
                  from hasTicket
                  where hasTicket.passengerID=P.passengerID and price>150 ) 
and DATEDIFF(year,P.birthDate,GETDATE())<18 and A.countryCode=2 -- ���� ������ ��� ��� 2 ���� �� ���"� 
group by  P.passengerID,P.passengerFirstName,P.passengerLastName,P.birthDate
having count(P.passengerID)<2

--------------------------------------------Q3-----------------------------------------------------------
select cA.checkPointNum
from Passport as P inner join checkedAt as cA on P.passengerID=cA.passengerID and P.serialNum=cA.serialNum inner join check_Point as cP on cP.checkPointNum=cA.checkPointNum  
where not exists ( select cA1.checkPointNum
                   from checkedAt as cA1
                   where P.passengerID=cA1.passengerID and P.countryCode=2)
and (select count(cA1.passengerID)
     from checkedAt as cA1
     where P.passengerID=cA1.passengerID  and P.countryCode=6)>1500 -- ��� 6 �� ����� ���� �� �������

--------------------------------------------Q4-----------------------------------------------------------
select F.flightID,Ato.airportName as AirPortTo,Afrom.airportName as AirPortFrom
from Flight as F inner join Airport as ATo on F.toAirportCode=ATo.airportCode inner join Airport as AFrom on F.fromAirportCode=AFrom.airportCode
where F.stops=0 and ((ATO.countryCode IN(1,2) or AFrom.countryCode IN(1,2)) and AFrom.countryCode<>ATO.countryCode) and (F.seatsNum*0.8)<(select count(distinct T.passengerID)
                                                                                                 from hasTicket as T inner join Flight as F on T.flightID=F.flightID
                                                                                                 where T.flightID=F.flightID) 
-- AFrom.countryCode<>ATO.countryCode �� �� ����� ���� ����"� ����� ���'
--------------------------------------------Q5-----------------------------------------------------------

select P.passengerID,P.passengerFirstName +' '+p.passengerLastName as FullName,count(distinct T.flightID) as TicketNumbers,count(distinct cA.checkDateTime) as ChecksNumbers
from Passenger as P inner join hasTicket as T on P.passengerID=T.passengerID inner join checkedAt as cA on T.passengerID=cA.passengerID 
where (T.price/T.luggageWeight)<20
group by P.passengerID,P.passengerFirstName,p.passengerLastName
having count(distinct T.flightID) < count(distinct cA.checkDateTime)
order by count(distinct T.flightID) DESC, FullName

-- ������ �� ���� "�����" �������� ���� �� �� ������ ��� ��� ����� ��� �� ���� ����� ���
-- ����� ��� ���� ���� ����� ����� ��� ����� �����

--------------------------------------------Trigger6-----------------------------------------------------------
create trigger checkPassport
on checkedAt
after insert, update as
Declare @serialNum char(8), @checkTime datetime
select @serialNum=I.serialNum, @checkTime=I.checkDateTime
from INSERTED as I
if (exists( select P.serialNum
            from Passport as P
            where P.serialNum=@serialNum and P.validUntilDate< GETDATE())
or 1<= (select count(*)
       from checkedAt as cA
       where cA.serialNum=@serialNum and cA.checkDateTime=@checkTime))
begin
print 'Cannot insert same check Times or when passport is invalid'
rollback
end

--------------------------------------------PROC7-----------------------------------------------------------

Create Procedure Question7
@kindofsearch smallint,
@NumberOfCheck int output, 
@NumberRejCheck int output, 
@NumberOfCheckTwoWeek int output,
@NumberOfCheckLastMonth int output
as
begin 
if(@kindofsearch=1)
begin
select @NumberOfCheck= (select count(*)
                        from checkedAt as cA)
select @NumberRejCheck=(select count(*)
                        from checkedAt as cA
                        where cA.result like 'D')
select @NumberOfCheckTwoWeek=(select count(*)
                              from checkedAt as cA
                              where DATEDIFF(day,cA.checkDateTime,GETDATE()) between 0 and 14)
select @NumberOfCheckLastMonth=(select count(*)
                                from checkedAt as cA
                                where DATEDIFF(day,cA.checkDateTime,GETDATE()) between 0 and 30)
end
else if(@kindofsearch=2)
begin
create table numCheckOnYear
(
month_Name nvarchar(7),
numberofcheck int
)
Declare @i int
set @i=1
While(@i<=12) -- ������ ������ ���� �� ����� �� �� �����, ��� ��� ��� ���� 0 ������� ���� ��� ����� ���� �� ����� 
begin
insert into numCheckOnYear
select case -- ��� ����� ���� ���� ������ ����� ������ �� �� ����� ����� �� ����
when @i=1 then N'�����'
when @i=2 then N'������'
when @i=3 then N'���'
when @i=4 then N'�����'
when @i=5 then N'���'
when @i=6 then N'����'
when @i=7 then N'����'
when @i=8 then N'������'
when @i=9 then N'������'
when @i=10 then N'�������'
when @i=11 then N'������'
when @i=12 then N'�����'
 end as N'����', count(cA.serialNum)
from checkedAt as cA
where YEAR(GETDATE())=YEAR(cA.checkDateTime) and MONTH(cA.checkDateTime)=@i
set @i=@i+1
end
end
else 
begin
print 'Wrong Command'
end
end

--  ���� �� ����������
Declare @NumberOfCheck int 
Declare @NumberRejCheck int
Declare @NumberOfCheckTwoWeek int 
Declare @NumberOfCheckLastMonth int
EXECUTE Question7 @kindofsearch=1, -- ��� ���� ����� �� ������
@NumberOfCheck=@NumberOfCheck output , 
@NumberRejCheck=@NumberRejCheck output , 
@NumberOfCheckTwoWeek=@NumberOfCheckTwoWeek output ,
@NumberOfCheckLastMonth=@NumberOfCheckLastMonth  output
PRINT N'���� ������ ������:' + Convert(NVARCHAR,@NumberOfCheck)
PRINT N'���� ������:' + Convert(NVARCHAR,@NumberRejCheck )
PRINT N'���� ������� �������� ��������:' + Convert(NVARCHAR,@NumberOfCheckTwoWeek)
PRINT N'���� ������� ����� ������:' + Convert(NVARCHAR,@NumberOfCheckLastMonth)

--------------------------------------------FUNC8-----------------------------------------------------------
Create Function FlightexperienceCategory(@type char(2))
returns table
as 
return(
select E.EmployeeCode,case 
when DATEDIFF(YEAR,E.startWorkingDate,GETDATE())<6 then N'���'
when DATEDIFF(YEAR,E.startWorkingDate,GETDATE()) between 6 and 15 then N'�����'
when DATEDIFF(Year,E.startWorkingDate,GETDATE())>15 then N'����'
end as experienceCategory
from flightEmployee as E
where E.finishWorkingDate is null and E.typeEmp=@type)

select *
from FlightexperienceCategory('MP')

-- ���� ������ �� �� ������� ����� ������ ����� ��� ���� ������ ����� �� ����� �� ������