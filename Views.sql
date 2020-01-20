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
		0 as 'Company',
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

Create or alter view DayReservationsMonetary
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

Create view DayReservationsNotFullyPaidYet
as
	Select Dr.ReservationID,
		Dr.Name,
		Dr.Phone, Dr.Mail,
		Dr.Paid,
		Dr.Reservation_Date
	from DayReservationsMonetary as Dr
		inner join Reservation
			on Reservation.Reservation_ID = Dr.ReservationID
		inner join Conference_Day
			on Conference_Day.Conference_Day_ID = Reservation.Reservation_ID
	Where dbo.SumToPay(Reservation.Conference_Day_ID, 
	Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count) > (Select Sum(Payment.Amount_Paid)
																			from Payment
																			Where Payment.Reservation_ID = Reservation.Reservation_ID
																			)
	and DATEDIFF(day, Conference_Day.Date, CONVERT(date, GETDATE())) <= 3

Create view DayReservationsOverpaid
as
	Select Dr.ReservationID,
		Dr.Name,
		Dr.Phone, Dr.Mail,
		Dr.Paid,
		Dr.Reservation_Date
	from DayReservationsMonetary as Dr
		inner join Reservation
			on Reservation.Reservation_ID = Dr.ReservationID
	Where dbo.SumToPay(Reservation.Conference_Day_ID, 
	Reservation.Normal_Ticket_Count, Reservation.Student_Ticket_Count) < (Select Sum(Payment.Amount_Paid)
																			from Payment
																			Where Payment.Reservation_ID = Reservation.Reservation_ID
																			)










