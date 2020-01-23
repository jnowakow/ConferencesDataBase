Create or alter view upcomingConferences
as
	Select Conference.Conference_Name, Conference_Day.Date, City + ', ' + Country as Place,
		Sum( dbo.CurrentTicketPrice(Conference_Day.Conference_Day_ID, Conference_Day.Date, Convert(date, GETDATE()))) as Current_Ticket_Price,
		Min( dbo.FreePlacesForConferenceDay(Conference_Day.Conference_Day_ID) ) as Free_Places
	From Conference
		inner join Conference_Day
			on Conference_Day.Conference_ID = Conference.Conference_ID
		left join Discount
			on Discount.Conference_Day_ID = Conference_Day.Conference_Day_ID
		inner join Conference_Place
			on Conference_Place.Place_ID = Conference.Place_ID
	Where Conference_Day.is_Cancelled = 0
	    and Conference_Day.Date > Convert(date, getdate())
	Group By  Conference.Conference_Name, Conference_Day.Date, City + ', ' + Country
    with rollup


Create or alter view availableConferences
as
	Select *
	From upcomingConferences
	Where upcomingConferences.Free_Places > 0

	
create view upcomingWorkshops
as
	select Conference.Conference_Name, Conference_Day.Date,
		Workshop_In_Day.[From] as "From",
		Workshop_In_Day.[To] as "To",
		Workshop_In_Day.Price as Ticket_Price,
		dbo.FreePlacesForWorkshopInDay(Workshop.Workshop_ID, Conference_Day.Conference_Day_ID) as Available_Places
	from Conference
		inner join Conference_Day
			on Conference_Day.Conference_ID = Conference.Conference_ID
		inner join Workshop_In_Day
			on Workshop_In_Day.Conference_Day_ID = Conference_Day.Conference_Day_ID
		inner join Workshop
			on Workshop_In_Day.Workshop_ID = Workshop.Workshop_ID
	where Workshop_In_Day.Is_Cancelled = 0
	and ( Conference_Day.Date > Convert(date, getdate()) 
	or ( Conference_Day.Date = Convert(date, getdate()) and  Workshop_In_Day.[From] > Convert(time, getdate()) ) )



create view availableWorkshops
as
	select *
	from upcomingWorkshops
	where upcomingWorkshops.Available_Places > 0


create view Personal_Identifier_Badge
as
	select Person.First_Name, Person.Last_Name, Conference.Conference_Name,
		case
			When Client.Client_ID = Person.Client_ID Then 'Individual Client'
			Else  (Select Company.Company_Name From Company Where Company.Client_ID = Client.Client_ID)
			End
		as Company
	From Person
		inner join Conference_Day_Participant
			on Conference_Day_Participant.Person_ID = Person.Person_ID
		inner join Reservation
			on Reservation.Reservation_ID = Conference_Day_Participant.Reservation_ID
		inner join Client
			on Client.Client_ID = Reservation.Client_ID 
		inner join Conference_Day
			on Conference_Day.Conference_Day_ID = Reservation.Conference_Day_ID
		inner join Conference
			on Conference.Conference_ID = Conference_Day.Conference_Day_ID

create or alter view DayReservations
as
	select Reservation.Reservation_ID as 'ReservationID',
		0 as 'Company',
		Person.First_Name + ' ' + Person.Last_Name as Name,
		Person.Phone, Person.Mail,
		Reservation.Student_Ticket_Count as 'Student Tickets',
		Reservation.Normal_Ticket_Count as 'Normal Tickets',
		Reservation.Reservation_Date,
	    Reservation.Is_Cancelled

	from Reservation
		left join Conference_Day_Participant
			on Conference_Day_Participant.Reservation_ID = Reservation.Reservation_ID
		inner join Client
			on Client.Client_ID = Reservation.Client_ID
		inner join Person
			on Person.Client_ID = Client.Client_ID
	union
	select Reservation.Reservation_ID,
		1 as 'Company',
		Company.Company_Name,
		Company.Phone, Company.Mail,
		Reservation.Student_Ticket_Count as 'Student Tickets',
		Reservation.Normal_Ticket_Count as 'Normal Tickets',
		Reservation.Reservation_Date,
	    Reservation.Is_Cancelled
	from Reservation
		left Join Conference_Day_Participant
			on Conference_Day_Participant.Reservation_ID = Reservation.Reservation_ID
		inner join Client
			on Client.Client_ID = Reservation.Client_ID
		inner join Company
			on Company.Client_ID = Client.Client_ID



create or alter view CancelledDayReservations
as 
	select *
	from DayReservations as Dr
	where (select Reservation.Is_Cancelled from Reservation where Reservation.Reservation_ID = Dr.ReservationID) = 1




create or alter view DayReservationsNotFilledWithParticipants
as
	select Dr.ReservationID,
		Dr.Company,
		Dr.Name,
		Dr.Phone, Dr.Mail,
		Dr.[Student Tickets],
		(select Count(*)
			from Conference_Day_Participant as ConfPart
			where ConfPart.Student = 1
			and ConfPart.Reservation_ID = Reservation.Reservation_ID
			)  as 'Student Participants',
		Dr.[Normal Tickets],
		
		(select Count(*)
			from Conference_Day_Participant as ConfPart
			where ConfPart.Student = 0
			and ConfPart.Reservation_ID = Reservation.Reservation_ID
			) as 'Normal Participants',
		Reservation.Reservation_Date
	from DayReservations as Dr
		inner join Reservation
			on Reservation.Reservation_ID = Dr.ReservationID
		
	where Reservation.Student_Ticket_Count > (select Count(*)
												From Conference_Day_Participant as ConfPart
												where ConfPart.Student = 1
												and ConfPart.Reservation_ID = Reservation.Reservation_ID
														) 
	or Reservation.Normal_Ticket_Count > (select Count(*)
												from Conference_Day_Participant as ConfPart
												where ConfPart.Student = 0
												and ConfPart.Reservation_ID = Reservation.Reservation_ID)

create or alter view WorkshopReservations
as
	select Workshop_reservation.Reservation_ID as 'ReservationID',
		0 as 'Company',
		Person.First_Name + ' ' + Person.Last_Name as Name,
		Person.Phone, Person.Mail,
		Workshop_reservation.Ticket_Count as 'Tickets',
		Reservation.Reservation_Date,
	    Workshop_Reservation.Is_Cancelled

	from Workshop_reservation
		inner join Reservation
			on Reservation.Reservation_ID = Workshop_reservation.Reservation_ID
		inner join Client
			on Client.Client_ID = Reservation.Client_ID
		inner join Person
			on Person.Client_ID = Client.Client_ID
	union
	select Workshop_reservation.Workshop_Reservation_ID,
		0 as 'Company',
		Company.Company_Name,
		Company.Phone, Company.Mail,
		Workshop_reservation.Ticket_Count as 'Tickets',
		Reservation.Reservation_Date,
	    Workshop_Reservation.Is_Cancelled

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
	where Is_Cancelled = 1


create or alter view WorkshopReservationsNotFilledWithParticipants
as
	select Wr.ReservationID,
		Wr.Company,
		Wr.Name,
		Wr.Phone, Wr.Mail,
		Wr.Tickets,
		(select count(*)
			from Workshop_Participant as WPart
			where WPart.Workshop_Reservation_ID = Workshop_reservation.Reservation_ID
			) as 'Current Participants',
		Wr.Reservation_Date
	from WorkshopReservations as Wr
		inner join Workshop_reservation
			on Workshop_reservation.Reservation_ID = Wr.ReservationID
		
	where  Workshop_reservation.Ticket_Count > (select count(*)
			from Workshop_Participant as WPart
			where WPart.Workshop_Reservation_ID = Workshop_reservation.Reservation_ID
			)



create or alter view ReservationsMonetary
as
	select Reservation.Reservation_ID as ReservationID,
		Person.First_Name + ' ' + Person.Last_Name as Name,
		Person.Phone, Person.Mail,
		dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count) as 'To pay',
		(select sum(Payment.Amount_Paid)
			from Payment
			where Payment.Reservation_ID = Reservation.Reservation_ID
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
	select Reservation.Reservation_ID,
		Company.Company_Name as Name,
		Company.Phone, Company.Mail,
		dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count) as 'To pay',
		(select Sum(Payment.Amount_Paid)
			from Payment
			where Payment.Reservation_ID = Reservation.Reservation_ID
			) as 'Paid',
		Reservation.Reservation_Date
	from Reservation
		inner join Client
			on Client.Client_ID = Reservation.Client_ID
		inner join Company
			on Company.Client_ID = Client.Client_ID
		inner join Conference_Day
			on Conference_Day.Conference_Day_ID = Reservation.Conference_Day_ID

create or alter view ReservationsNotFullyPaidYet
as
	select RM.ReservationID,
		RM.Name,
		RM.Phone, RM.Mail,
		RM.Paid,
		dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count)
		+ 
		( select sum (dbo.SumToPayForWorkshop(Workshop_reservation.Workshop_ID, Workshop_reservation.Conference_Day_ID, Workshop_reservation.Ticket_Count)) 
		from Workshop_reservation
		where
		  Workshop_reservation.Reservation_ID = RM.ReservationID
		)	 as 'Sum to Pay',
		RM.Reservation_Date
	from ReservationsMonetary as RM
		inner join Reservation
			on Reservation.Reservation_ID = RM.ReservationID
		inner join Conference_Day
			on Conference_Day.Conference_Day_ID = Reservation.Conference_Day_ID
	Where dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count) 
	+ 
	( select sum (dbo.SumToPayForWorkshop(Workshop_reservation.Workshop_ID, Workshop_reservation.Conference_Day_ID, Workshop_reservation.Ticket_Count))
		from Workshop_reservation
		where
		  Workshop_reservation.Reservation_ID = RM.ReservationID
	)
	> RM.Paid
	and DATEDIFF(day, RM.Reservation_Date, CONVERT(date, GETDATE())) > 7

create or alter view ReservationsOverpaid
as
	select RM.ReservationID,
		RM.Name,
		RM.Phone, RM.Mail,
		RM.Paid,
		dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count)
		+ 
		( select sum (dbo.SumToPayForWorkshop(Workshop_reservation.Workshop_ID, Workshop_reservation.Conference_Day_ID, Workshop_reservation.Ticket_Count)) 
		from Workshop_reservation
		where
		  Workshop_reservation.Reservation_ID = RM.ReservationID
		)	 as 'Sum to Pay',
		RM.Reservation_Date
	from ReservationsMonetary as RM
		inner join Reservation
			on Reservation.Reservation_ID = RM.ReservationID
	Where dbo.SumToPay(Reservation.Conference_Day_ID, Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count) 
	+ 
	( select sum (dbo.SumToPayForWorkshop(Workshop_reservation.Workshop_ID, Workshop_reservation.Conference_Day_ID, Workshop_reservation.Ticket_Count))
		from Workshop_reservation
		where
		  Workshop_reservation.Reservation_ID = RM.ReservationID
	)
	< RM.Paid

create view ConferencesParticipants
as
    select Conference.Conference_Name as 'Conference Name',
           CD.Date as Date,
           P.First_Name + ' ' + P.Last_Name as Name,
           P.Phone,
           P.Mail

    from Conference
        inner join Conference_Day CD
            on Conference.Conference_ID = CD.Conference_ID
        inner join Reservation R
            on CD.Conference_Day_ID = R.Conference_Day_ID
        inner join Conference_Day_Participant CDP
            on CDP.Reservation_ID = R.Reservation_ID
        inner join Person P
            on CDP.Person_ID = P.Person_ID

create view WorkshopParticipants
as
    select Conference.Conference_Name as 'Conference Name',
           CD.Date as Date,
           W.Subject as 'Workshop Subject',
           P.First_Name + ' ' + P.Last_Name as Name,
           P.Phone,
           P.Mail

    from Conference
        inner join Conference_Day CD
            on Conference.Conference_ID = CD.Conference_ID
        inner join Reservation R
            on CD.Conference_Day_ID = R.Conference_Day_ID
        inner join Workshop_reservation WR
            on WR.Reservation_ID = R.Reservation_ID
        inner join Workshop W
            on W.Workshop_ID = WR.Workshop_ID
        inner join Workshop_Participant WP
            on WR.Workshop_Reservation_ID = WP.Workshop_Reservation_ID
        inner join Person P
            on WP.Person_ID = P.Person_ID


create or alter view HighestNumberOfReservations
as
    select * from (
            select  P.First_Name + ' ' + P.Last_Name as Name, P.Phone, P.Mail, count(Reservation_ID) as 'Reservations number'
            from Reservation R
            inner join Client C
                on C.Client_ID = R.Client_ID
            inner join Person P
                on C.Client_ID = P.Client_ID
            group by C.Client_ID, P.First_Name + ' ' + P.Last_Name , P.Phone, P.Mail

            union

            select CPY.Company_Name as Name, CPY.Phone, CPY.Mail, count(Reservation_ID) as 'Reservations number'
            from Reservation R
            inner join Client C
                on C.Client_ID = R.Client_ID
            inner join Company CPY
                on C.Client_ID = CPY.Client_ID
            group by C.Client_ID, CPY.Company_Name, CPY.Phone, CPY.Mail
        ) as CI

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

create or alter view ReturnedPayments
as
    select * from Payment
    where Amount_Paid < 0