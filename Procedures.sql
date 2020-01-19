--procedure to find location's id or add this location if absent
create procedure addPLace(
@country varchar(40),
@city varchar(40),
@street varchar(40),
@postalCode varchar(8),
@placeID int output


)
as
    begin
        set @placeID = (select Place_ID from ConferencePlace where City = @city
                                                                and Country = @country
                                                                and Street = @street
                                                                and Postal_Code = @postalCode)

        if @placeID is null
        begin
            insert into ConferencePlace values (@country, @city, @street, @postalCode)
            set @placeID = @@IDENTITY
        end

    end


--procedure to add conference
create procedure addConference(
@name as varchar(100),
@startDate as date,
@endDate as date,
@country as varchar(40),
@city as varchar(40),
@street as varchar(40),
@postalCode as varchar(8),
@studentDiscount as decimal(3,2)
)
as
    begin
        if @endDate >= @startDate and @startDate > getdate()
            begin
                declare @PLACE_ID int -- place's id to be set into Conference table
                exec findPlaceId
                    @country,
                    @city,
                    @street,
                    @postalCode,
                    @placeID = @PLACE_ID output


                insert into Conferences values(@name, @startDate, @endDate, @PLACE_ID, @studentDiscount)
            end
        else
        begin
            raiserror ('Wrong dates!', -1 , -1 )
        end

    end

--procedure to add day conference
create procedure addConferenceDay(
@conferenceID as int,
@date as date,
@participantsLimit as int,
@basePrice as money
)
as
    begin 
        if @date >= (select Conferences.Start_Date from Conferences where Conference_ID = @conferenceID)
               and @date <= (select Conferences.End_Date from Conferences where Conference_ID = @conferenceID)
        begin
            insert into Conference_Day(Conference_ID, Date, Participants_Limit, Base_Price)
            values (@conferenceID, @date, @participantsLimit, @basePrice)
        end
        else
        begin
            raiserror ('Wrong dates!', -1 , -1)
        end
    end



--procedure to add workshop to day
create procedure addWorkshopToDay(
    @workshopID as int,
    @conferenceDayID as int,
    @participantsLimit as int,
    @price as money,
    @room as varchar(10),
    @from as time,
    @to as time
)
as
    begin
        if @from < @to
        begin
            insert into Workshops_In_Day(workshop_id, conference_day_id, participants_limit, price, room, [from], [to])
            values (@workshopID, @conferenceDayID, @participantsLimit, @price, @room, @from, @to)
        end
        else
        begin
            raiserror ('Wrong start and end hours!', -1, -1)
        end
    end


--add payment
create procedure addPayment(
    @reservationID int,
    @amount money
)
as
    begin
        if @amount != 0
        begin
            insert into Payment values (getdate(), @amount, @reservationID) -- amount > 0 isn't check because it is assumed that some money can be returned
        end
        else
        begin
            raiserror ('No money transferred', -1, -1)
        end
    end

create procedure addClient(
    @clientID int output
)
as
    begin
        insert into Client default values
        set @clientID = @@IDENTITY
    end



--this procedure add new company to table company and add client for this company in table company
create procedure addCompany(
    @name varchar(40),
    @address varchar(40),
    @city varchar(40),
    @Country varchar(40),
    @Phone int,
    @Mail varchar(100),
    @Contact_Person varchar(50)
)
as
    begin
        declare @clientID int
        exec addClient
        @clientID = @clientID output

        insert into Company values (@name, @clientID, @address, @city, @Country, @Phone, @Mail, @Contact_Person)
    end



--this procedure add new person to table person and add client for this person in table company
create procedure addPerson(
    @firstName varchar(40),
    @lastName varchar(40),
    @address varchar(40),
    @city varchar(40),
    @country varchar(40),
    @phone int,
    @mail varchar(100)
)
as
    begin
        declare @clientID int
        exec addClient
        @clientID = @clientID output

        insert into Person values (@clientID, @firstName, @lastName, @address, @city, @country, @phone, @mail)

    end



create procedure addReservation(
    @normalTicketCount int,
    @studentTicketCount int,
    @clientID int,
    @conferenceDayID int,
    @reservationID int output
)
as
    begin
        if (select FreePlacesForConferenceDay(@conferenceDayID) >= @normalTicketCount + @studentTicketCount)

        begin
            declare @sumToPay money
            set @sumToPay = (select SumToPay(@conferenceDayID, @normalTicketCount, @studentTicketCount))

            insert into Reservation(Reservation_Date, Normal_Ticket_Count, Student_Ticket_Count, Amount_To_Pay, Client_ID, Conference_Day_ID)
            values (getdate(), @normalTicketCount, @studentTicketCount, @sumToPay, @clientID, @conferenceDayID)
            set @reservationID = @@IDENTITY
        end
        else
        begin
            raiserror ('Too few tickets left!', -1 , -1)
        end
    end


create procedure addPersonToReservation(
	@reservationID int,
	@firstName varchar(40),
	@lastName varchar(40),
	@address varchar(40),
	@city varchar(40),
	@country varchar(40)
	)
as
	begin
		declare @personID int = (Select Person_ID
			FROM Person
			WHERE 
			Person.First_Name = @firstName
			AND Person.Last_Name = @lastName
			AND Person.Address = @address
			AND Person.City = @city
			AND Person.Country = @country
		) 
		INSERT INTO Conference_Day_Participants VALUES(@personID, @reservationID)
	end

create procedure addPersonToWorkshopReservation(
	@reservationID int,
	@firstName varchar(40),
	@lastName varchar(40),
	@address varchar(40),
	@city varchar(40),
	@country varchar(40),
	@workshopSubject varchar(100)
	)
as
	begin
		declare @personID int = (Select Person_ID
			FROM Person
			WHERE 
			Person.First_Name = @firstName
			AND Person.Last_Name = @lastName
			AND Person.Address = @address
			AND Person.City = @city
			AND Person.Country = @country
		) 
		declare @dayId int = (Select Reservation.Conference_Day_ID
			FROM Reservation 
			Where Reservation.Reservation_ID = @reservationID
			)

		declare @workshopID int = (Select Workshops.Workshop_ID
			FROM Workshops
				INNER JOIN Workshops_In_Day
					ON Workshops_In_Day.Workshop_ID = Workshops.Workshop_ID
			WHERE Workshops_In_Day.Conference_Day_ID = @dayId
			AND Workshops.Subject = @workshopSubject
			)



		INSERT INTO Workshops_Participants VALUES(@personID, @reservationID, @workshopID, @dayId)
	end



create procedure addWorkshopReservation(
        @reservationID int,
        @workshopID int,
        @conferenceDayID int,
        @ticketsCount int,
        @workshopReservationID int output
)
as
    begin
        if @ticketsCount < FreePlacesForWorkshopInDay(@workshopID, @conferenceDayId)
        begin
            declare @sumToPay money
            set @sumToPay = (select SumToPayForWorkshop(@workshopID, @conferenceDayID, @ticketsCount))

            update Reservation
            set Amount_To_Pay = Amount_To_Pay + @sumToPay
            where Reservation_ID = @reservationID

            insert into Workshop_Reservation(reservation_id, workshop_id, conference_day_id, ticket_count)
             values (@reservationID, @workshopID, @conferenceDayID, @ticketsCount)
            set @workshopReservationID = @@IDENTITY
        end
        else
        begin
            raiserror ('Too few tickets left for this workshop!', -1, -1)
        end
    end


--Procedure to add discount for day
create procedure addDiscountToDay(
    @percentage decimal(2,2),
    @daysBefore int,
    @conferenceDayID int
)
as
    begin
        insert into Discounts values (@percentage, @daysBefore, @conferenceDayID)
    end


create procedure addWorkshop (
	@subject varchar (100),
	@description varchar (100),
	@workshopID int output
)
as
	begin
		insert into Workshops values (@subject, @description)
		set @workshopID = @@IDENTITY
	end


create procedure addStudentCard (
	@personID int,
	@university varchar(100),
	@faculty varchar(100)
)
as
	begin
		insert into Student values (@personID, @university, @faculty, 1)
	end

		

