Create view upcomingConferences 
as
	Select Conferences.Conference_Name, Conference_Day.Date, 
		Sum( dbo.CurrentTicketPrice(Conference_Day.Conference_Day_ID, Conference_Day.Date, Convert(date, GETDATE()))) as Current_Ticket_Price,
		Min( dbo.FreePlacesForConferenceDay(Conference_Day.Conference_Day_ID) ) as Free_Places
	From Conferences
		inner join Conference_Day
			on Conference_Day.Conference_ID = Conferences.Conference_ID
		inner join Discounts
			on Discounts.Conference_Day_ID = Conference_Day.Conference_Day_ID
		inner join ConferencePlace
			on ConferencePlace.Place_ID = Conferences.Conference_ID
	Where Conference_Day.is_Cancelled = 0
		and Conference_Day.Date > Convert(date, getdate())
	Group By  Conferences.Conference_Name, Conference_Day.Date
	With Rollup

Create view availableConferences 
as
	Select *
	From upcomingConferences
	Where upcomingConferences.Free_Places > 0

	
Create view upcomingWorkshops
as
	Select Conferences.Conference_Name, Conference_Day.Date, 
		[Workshops_In_Day.From] as "From",
		[Workshops_In_Day.To] as "To",
		Workshops_In_Day.Price as Ticket_Price, 
		FreePlacesForWorkshopInDay(Workshops.Workshop_ID, Conference_Day.Conference_Day_ID) as Available_Places
	From Conferences
		inner join Conference_Day
			on Conference_Day.Conference_ID = Conferences.Conference_ID
		inner join Workshops_In_Day
			on Workshops_In_Day.Conference_Day_ID = Conference_Day.Conference_Day_ID
		inner join Workshops
			on Workshops_In_Day.Workshop_ID = Workshops.Workshop_ID
	Where Workshops_In_Day.Is_Cancelled = 0
	and ( Conference_Day.Date > Convert(date, getdate()) 
	or ( Conference_Day.Date = Convert(date, getdate()) and  [Workshops_In_Day.From] > Convert(time, getdate()) ) )
	Order by Conference_Day.Date


Create view availableWorkshops
as
	Select *
	From upcomingWorkshops
	Where upcomingWorkshops.Available_Places > 0
	Order by upcomingWorkshops.Date


Create view Personal_Identifier_Badge
as
	Select Person.First_Name, Person.Last_Name, Conferences.Conference_Name,
		Case 
			When Client.Client_ID = Person.Client_ID Then 'Individual Client'
			Else  (Select Company.Company_Name From Company Where Company.Client_ID = Client.Client_ID)
			End
		as Company
	From Person
		inner join Conference_Day_Participants
			on Conference_Day_Participants.Person_ID = Person.Person_ID
		inner join Reservation
			on Reservation.Reservation_ID = Conference_Day_Participants.Reservation_ID
		inner join Client
			on Client.Client_ID = Reservation.Client_ID 
		inner join Conference_Day
			on Conference_Day.Conference_Day_ID = Reservation.Conference_Day_ID
		inner join Conferences
			on Conferences.Conference_ID = Conference_Day.Conference_Day_ID

create or alter view DayReservations
as
	Select Reservation.Reservation_ID as 'ReservationID',
		0 as 'Company',
		Person.First_Name + ' ' + Person.Last_Name as Name,
		Person.Phone, Person.Mail,
		Reservation.Student_Ticket_Count as 'Student Tickets',
		Reservation.Normal_Ticket_Count as 'Normal Tickets',
		Reservation.Reservation_Date

	from Reservation
		inner Join Conference_Day_Participants
			on Conference_Day_Participants.Reservation_ID = Reservation.Reservation_ID
		inner join Client
			on Client.Client_ID = Reservation.Client_ID
		inner join Person
			on Person.Client_ID = Client.Client_ID
	union
	Select Reservation.Reservation_ID,
		1 as 'Company',
		Company.Company_Name,
		Company.Phone, Company.Mail,
		Reservation.Student_Ticket_Count as 'Student Tickets',
		Reservation.Normal_Ticket_Count as 'Normal Tickets',
		Reservation.Reservation_Date
	from Reservation
		inner Join Conference_Day_Participants
			on Conference_Day_Participants.Reservation_ID = Reservation.Reservation_ID
		inner join Client
			on Client.Client_ID = Reservation.Client_ID
		inner join Company
			on Company.Client_ID = Client.Client_ID





create or alter view CancelledDayReservations
as 
	Select *
	from DayReservations as Dr
	where (Select Reservation.Is_Cancelled From Reservation Where Reservation.Reservation_ID = Dr.ReservationID) = 1




Create or alter view DayReservationsNotFilledWithParticipants
as
	Select Dr.ReservationID,
		Dr.Company,
		Dr.Name,
		Dr.Phone, Dr.Mail,
		Dr.[Student Tickets],
		(Select Count(*)
			From Conference_Day_Participants as ConfPart
			Where ConfPart.Student = 1
			and ConfPart.Reservation_ID = Reservation.Reservation_ID
			)  as 'Student Participants',
		Dr.[Normal Tickets],
		
		(Select Count(*)
			From Conference_Day_Participants as ConfPart
			Where ConfPart.Student = 0
			and ConfPart.Reservation_ID = Reservation.Reservation_ID
			) as 'Normal Participants',
		Reservation.Reservation_Date
	from DayReservations as Dr
		inner Join Reservation
			on Reservation.Reservation_ID = Dr.ReservationID
		
	Where Reservation.Student_Ticket_Count > (Select Count(*)
												From Conference_Day_Participants as ConfPart
												Where ConfPart.Student = 1
												and ConfPart.Reservation_ID = Reservation.Reservation_ID
														) 
	or Reservation.Normal_Ticket_Count > (Select Count(*)
												From Conference_Day_Participants as ConfPart
												Where ConfPart.Student = 0
												and ConfPart.Reservation_ID = Reservation.Reservation_ID
														) 

create or alter view WorkshopReservations
as
	Select Workshop_reservation.Reservation_ID as 'ReservationID',
		0 as 'Company',
		Person.First_Name + ' ' + Person.Last_Name as Name,
		Person.Phone, Person.Mail,
		Workshop_reservation.Ticket_Count as 'Tickets',
		Reservation.Reservation_Date

	from Workshop_reservation
		inner join Reservation
			on Reservation.Reservation_ID = Workshop_reservation.Reservation_ID
		inner join Client
			on Client.Client_ID = Reservation.Client_ID
		inner join Person
			on Person.Client_ID = Client.Client_ID
	union
	Select Workshop_reservation.Workshop_Reservation_ID,
		0 as 'Company',
		Company.Company_Name,
		Company.Phone, Company.Mail,
		Workshop_reservation.Ticket_Count as 'Tickets',
		Reservation.Reservation_Date
	from Workshop_reservation
		inner join Reservation
			on Reservation.Reservation_ID = Workshop_reservation.Reservation_ID
		inner join Client
			on Client.Client_ID = Reservation.Client_ID
		inner join Company
			on Company.Client_ID = Client.Client_ID




create or alter view CancelledWorkshopReservations
as 
	Select *
	from WorkshopReservations as Wr
	where (Select Workshop_reservation.Is_Cancelled From Workshop_reservation Where Workshop_reservation.Reservation_ID = Wr.ReservationID) = 1




Create or alter view WorkshopReservationsNotFilledWithParticipants
as
	Select Wr.ReservationID,
		Wr.Company,
		Wr.Name,
		Wr.Phone, Wr.Mail,
		Wr.Tickets,
		(Select Count(*)
			From Workshops_Participants as WPart
			Where WPart.Workshop_Reservation_ID = Workshop_reservation.Reservation_ID
			) as 'Current Participants',
		Wr.Reservation_Date
	from WorkshopReservations as Wr
		inner Join Workshop_reservation
			on Workshop_reservation.Reservation_ID = Wr.ReservationID
		
	Where  Workshop_reservation.Ticket_Count > (Select Count(*)
			From Workshops_Participants as WPart
			Where WPart.Workshop_Reservation_ID = Workshop_reservation.Reservation_ID
			)



Create or alter view ReservationsMonetary
as
	Select Reservation.Reservation_ID as ReservationID,
		Person.First_Name + ' ' + Person.Last_Name as Name,
		Person.Phone, Person.Mail,
		dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count) as 'To pay',
		(Select Sum(Payment.Amount_Paid)
			from Payment
			Where Payment.Reservation_ID = Reservation.Reservation_ID
			) as 'Paid',
		Reservation.Reservation_Date

	from Reservation
		inner join Client
			on Client.Client_ID = Reservation.Client_ID
		inner join Person
			on Person.Client_ID = Client.Client_ID
		inner join Conference_Day
			on Conference_Day.Conference_Day_ID = Reservation.Conference_Day_ID
	union
	Select Reservation.Reservation_ID,
		Company.Company_Name as Name,
		Company.Phone, Company.Mail,
		dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count) as 'To pay',
		(Select Sum(Payment.Amount_Paid)
			from Payment
			Where Payment.Reservation_ID = Reservation.Reservation_ID
			) as 'Paid',
		Reservation.Reservation_Date
	from Reservation
		inner join Client
			on Client.Client_ID = Reservation.Client_ID
		inner join Company
			on Company.Client_ID = Client.Client_ID
		inner join Conference_Day
			on Conference_Day.Conference_Day_ID = Reservation.Conference_Day_ID

Create or alter view ReservationsNotFullyPaidYet
as
	Select Dr.ReservationID,
		Dr.Name,
		Dr.Phone, Dr.Mail,
		Dr.Paid,
		dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count)
		+ 
		( select sum (dbo.SumToPayForWorkshop(Workshop_reservation.Workshop_ID, Workshop_reservation.Conference_Day_ID, Workshop_reservation.Ticket_Count)) 
		from Workshop_reservation
		where
		  Workshop_reservation.Reservation_ID = Dr.ReservationID
		)	 as 'Sum to Pay',
		Dr.Reservation_Date
	from ReservationsMonetary as Dr
		inner join Reservation
			on Reservation.Reservation_ID = Dr.ReservationID
		inner join Conference_Day
			on Conference_Day.Conference_Day_ID = Reservation.Reservation_ID
	Where dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count) 
	+ 
	( select sum (dbo.SumToPayForWorkshop(Workshop_reservation.Workshop_ID, Workshop_reservation.Conference_Day_ID, Workshop_reservation.Ticket_Count))
		from Workshop_reservation
		where
		  Workshop_reservation.Reservation_ID = Dr.ReservationID
	)
	> Dr.Paid
	and DATEDIFF(day, Dr.Reservation_Date, CONVERT(date, GETDATE())) > 7

Create or alter view ReservationsOverpaid
as
	Select Dr.ReservationID,
		Dr.Name,
		Dr.Phone, Dr.Mail,
		Dr.Paid,
		dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count)
		+ 
		( select sum (dbo.SumToPayForWorkshop(Workshop_reservation.Workshop_ID, Workshop_reservation.Conference_Day_ID, Workshop_reservation.Ticket_Count)) 
		from Workshop_reservation
		where
		  Workshop_reservation.Reservation_ID = Dr.ReservationID
		)	 as 'Sum to Pay',
		Dr.Reservation_Date
	from ReservationsMonetary as Dr
		inner join Reservation
			on Reservation.Reservation_ID = Dr.ReservationID
	Where dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count) 
	+ 
	( select sum (dbo.SumToPayForWorkshop(Workshop_reservation.Workshop_ID, Workshop_reservation.Conference_Day_ID, Workshop_reservation.Ticket_Count))
		from Workshop_reservation
		where
		  Workshop_reservation.Reservation_ID = Dr.ReservationID
	)
	< Dr.Paid

create view ConferencesParticipants
as
    select Conferences.Conference_Name as 'Conference Name',
           CD.Date as Date,
           P.First_Name + ' ' + P.Last_Name as Name,
           P.Phone,
           P.Mail

    from Conferences
        inner join Conference_Day CD
            on Conferences.Conference_ID = CD.Conference_ID
        inner join Reservation R
            on CD.Conference_Day_ID = R.Conference_Day_ID
        inner join Conference_Day_Participants CDP
            on CDP.Reservation_ID = R.Reservation_ID
        inner join Person P
            on CDP.Person_ID = P.Person_ID

    order by Conferences.Conference_Name, CD.Date

create view WorkshopParticipants
as
    select Conferences.Conference_Name as 'Conference Name',
           CD.Date as Date,
           W.Subject as 'Workshop Subject',
           P.First_Name + ' ' + P.Last_Name as Name,
           P.Phone,
           P.Mail

    from Conferences
        inner join Conference_Day CD
            on Conferences.Conference_ID = CD.Conference_ID
        inner join Reservation R
            on CD.Conference_Day_ID = R.Conference_Day_ID
        inner join Workshop_reservation WR
            on WR.Reservation_ID = R.Reservation_ID
        inner join Workshops W
            on W.Workshop_ID = WR.Workshop_ID
        inner join Workshops_Participants WP
            on WR.Workshop_Reservation_ID = WP.Workshop_Reservation_ID
        inner join Person P
            on WP.Person_ID = P.Person_ID

    order by Conferences.Conference_Name, CD.Date, W.Subject

create view HighestNumberOfReservations
as
    select * from (
            select C.Client_ID, P.First_Name + ' ' + P.Last_Name as Name, P.Phone, P.Mail, count(*) as 'reservations number'
            from Client C
            inner join Person P
                on C.Client_ID = P.Client_ID
            group by C.Client_ID, P.First_Name + ' ' + P.Last_Name , P.Phone, P.Mail

            union

            select C.Client_ID, CPY.Company_Name as Name, CPY.Phone, CPY.Mail, count(*) as 'Reservations number'
            from Client C
            inner join Company CPY
                on C.Client_ID = CPY.Client_ID
            group by C.Client_ID, CPY.Company_Name, CPY.Phone, CPY.Mail
        ) as CI
    order by CI.[Reservations number] desc

create view HighestAmountPaidForReservations
as
    select * from (
            select C.Client_ID, P.First_Name + ' ' + P.Last_Name as Name, P.Phone, P.Mail, sum(Pmnt.Amount_Paid) as 'Amount paid'
            from Client C
            inner join Person P
                on C.Client_ID = P.Client_ID
            inner join Reservation R
                on C.Client_ID = R.Client_ID
            inner join Payment Pmnt
                on Pmnt.Reservation_ID = R.Reservation_ID
            group by C.Client_ID, P.First_Name + ' ' + P.Last_Name , P.Phone, P.Mail

            union

            select C.Client_ID, CPY.Company_Name as Name, CPY.Phone, CPY.Mail, sum(Pmnt.Amount_Paid) as 'Amount paid'
            from Client C
            inner join Company CPY
                on C.Client_ID = CPY.Client_ID
            inner join Reservation R
                on C.Client_ID = R.Client_ID
            inner join Payment Pmnt
                on Pmnt.Reservation_ID = R.Reservation_ID
            group by C.Client_ID, CPY.Company_Name, CPY.Phone, CPY.Mail
        ) as CI
    order by CI.[Amount paid] desc
