Create view upcoming_conferences 
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
	Group By  Conferences.Conference_Name, Conference_Day.Date
	With Rollup
	


